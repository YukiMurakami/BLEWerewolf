//
//  BWSendMessageManager.m
//  NearByMessageChat
//
//  Created by Yuki Murakami on 2016/02/07.
//  Copyright © 2016年 yuki. All rights reserved.
//

/*
 
 NearbyMessageAPIでは、すべての近接する端末同士で相互通信が張られ、メッセージがブロードキャスト的な送信になってしまう。
 そこで相手との通信確立用の専用メッセージを設定し、それによって送信相手を取得し、その相手のIDと自分のIDをメッセージにのせて送受信することにする。
 
 "advertiseMyDevice:<gameId>:<peripheralId>:<peripheralName>" 自分のIDを不特定多数の全員に知らせる (ペリフェラルのみ）
 （セントラルは個別に自分のIDを送る)
 "mes:<signalId>:<yourId>:<myId>:<message>" yourIDに対してメッセージを送信する
 送られるメッセージはすべて個別idを付与して送る（2重受信の防止)
 送り出すメッセージはその都度idをインクリメントする
 
 
 publishは配列にして５０個ほどは保存しておく（一斉送信など同時に複数のメッセージを送信する場合に必要）
 
 

*/

#import "BWSendMessageManager.h"
#import "BWUtility.h"
#import "NSObject+BlocksWait.h"
#import <GNSMessages.h>

const NSInteger saveNumberPublications = 30;

static NSString * const APIKey = @"AIzaSyDWFBySXYZ_jYsfO67lvzVTmC4LAaCb8JU";

@interface BWSendMessageManager ()

@property (nonatomic) GNSPermission *nearbyPermission;
@property (nonatomic) GNSMessageManager *messageManager;
@property (nonatomic) NSMutableArray  *publications;
@property (nonatomic) id<GNSSubscription> subscription;
@property (nonatomic) NSString *identificationId;
@property (nonatomic) NSInteger signalId;
@property (nonatomic) NSMutableArray *receivedSignalIds;


@property (nonatomic) NSMutableArray *centralIds;
@property (nonatomic) NSString *peripheralId;

@end

@implementation BWSendMessageManager

static BWSendMessageManager *sharedInstance = nil;

#pragma mark - Singleton
+ (instancetype)sharedInstance {
    @synchronized(self) {
        if(!sharedInstance) {
            sharedInstance = [[BWSendMessageManager alloc]initSharedInstance];
        }
    }
    return sharedInstance;
}

+ (void)resetSharedInstance {
    [sharedInstance.publications removeAllObjects];
    sharedInstance.subscription = nil;
    sharedInstance = nil;
}

- (id)initSharedInstance {
    self = [super init];
    if(self) {
        //初期化処理
        self.identificationId = [BWUtility getIdentificationString];
        self.publications = [NSMutableArray array];
        self.signalId = arc4random_uniform(1000000);
        self.receivedSignalIds = [NSMutableArray array];
        
        self.nearbyPermission = [[GNSPermission alloc]initWithChangedHandler:^(BOOL granted) {
            NSLog(@"nearbyPermission state change:%d",granted);
        }];
        [GNSPermission setGranted:YES];//ここで通信を許可する
        
        [GNSMessageManager setDebugLoggingEnabled:YES];//ログを出力するようにする
        
        self.messageManager = [[GNSMessageManager alloc]
            initWithAPIKey:APIKey
            paramsBlock:^(GNSMessageManagerParams *params) {
                params.microphonePermissionErrorHandler = ^(BOOL hasError) {
                    if(hasError) {
                        NSLog(@"Nearby works better if microphone use is allowed");
                    }
                };
                params.bluetoothPermissionErrorHandler = ^(BOOL hasError) {
                    if (hasError) {
                        NSLog(@"Nearby works better if Bluetooth use is allowed");
                    }
                };
                params.bluetoothPowerErrorHandler = ^(BOOL hasError) {
                    if (hasError) {
                        NSLog(@"Nearby works better if Bluetooth is turned on");
                    }
                };
            }];
        
        self.subscription = [self.messageManager
            subscriptionWithMessageFoundHandler:^(GNSMessage *message) {
                NSString *mes = [[NSString alloc]initWithData:message.content encoding:NSUTF8StringEncoding];
                [self receiveMessage:mes];
            } messageLostHandler:^(GNSMessage *message) {
            
            }];
    }
    return self;
}

- (void)setIsPeripheralParams:(BOOL)isPeripheral {
    self.isPeripheral = isPeripheral;
    
    if(self.isPeripheral) {
        self.centralIds = [NSMutableArray array];
    }
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)receiveMessage:(NSString*)mes {
    
    if(!self.isPeripheral) {
        //デバイスのアドバータイズなら受け取る
        //"advertiseMyDevice:<gameId>:<peripheralId>:<peripheralName>"
        if([[BWUtility getCommand:mes] isEqualToString:@"advertiseMyDevice"]) {
            NSArray *array = [mes componentsSeparatedByString:@":"];
            NSString *gameId = array[1];
            NSString *peripheralId = array[2];
            NSString *peripheralName = array[3];
            
            [self.delegate didReceiveAdvertiseGameroomInfo:@{@"gameId":gameId,@"peripheralId":peripheralId,@"peripheralName":peripheralName}];
        }
    }
    
    //通常メッセージは自分あてなら受け取る
    //"mes:<signalId>:<yourId>:<myId>:<message>"
    if([[BWUtility getCommand:mes] isEqualToString:@"mes"]) {
        NSArray *array = [mes componentsSeparatedByString:@":"];
        NSString *receiverId = array[2];
        NSString *senderId = array[3];
        NSString *message = array[4];
        NSInteger signalId = [array[1]integerValue];
        for(NSInteger i=5;i<array.count;i++) {
            message = [NSString stringWithFormat:@"%@:%@",message,array[i]];
        }
        if([receiverId isEqualToString:self.identificationId]) {//自分あてかどうか確認
            BOOL canReceive = NO;
            if(self.isPeripheral) {
                //ペリフェラルは担当セントラルからのメッセージのみ受信
                //ただしparticipateRequestだけは無条件で受信
                if([self.centralIds containsObject:senderId] || [array[4] isEqualToString:@"participateRequest"]) {
                    canReceive = YES;
                }
            } else {
                //セントラルは自分のペリフェラルからのメッセージのみ受信
                if([senderId isEqualToString:self.peripheralId]) {
                    canReceive = YES;
                }
            }
            if(![self.receivedSignalIds containsObject:@(signalId)] && canReceive) {
                [self.delegate didReceiveMessage:message senderId:senderId];
                [self.receivedSignalIds addObject:@(signalId)];
            }
        }
    }
}

#pragma mark - public methods

- (BOOL)addCentralIdsObject:(NSString*)centralId {
    if(![self.centralIds containsObject:centralId]) {
        [self.centralIds addObject:centralId];
        return YES;
    }
    return NO;
}

- (void)resetCentralIds {
    [self.centralIds removeAllObjects];
}

- (void)startAdvertiseGameRoomInfo:(NSString*)gameIdString {
    //"advertiseMyDevice:<gameId>:<peripheralId>:<peripheralName>" 自分のIDを不特定多数の全員に知らせる (ペリフェラルのみ）
    NSString *mes = [NSString stringWithFormat:@"advertiseMyDevice:%@:%@:%@",gameIdString,self.identificationId,[BWUtility getUserName]];
    GNSMessage *pubMessage = [GNSMessage messageWithContent:[mes dataUsingEncoding:NSUTF8StringEncoding]];
    [self.publications addObject: [self.messageManager publicationWithMessage:pubMessage]];
    
    if(self.publications.count > saveNumberPublications) {
        [self.publications removeObjectAtIndex:0];
    }
}

- (void)sendMessageForPeripheral:(NSString*)message {
    [self sendMessageWithAddressId:message toId:self.peripheralId];
}

- (void)sendMessageForAllCentrals:(NSString*)message {
    for(NSInteger i=0;i<self.centralIds.count;i++) {
        [NSObject performBlock:^{
            [self sendMessageWithAddressId:message toId:self.centralIds[i]];
        } afterDelay:0.05*i];
    }
}

- (void)sendMessageWithAddressId:(NSString*)message toId:(NSString*)toId {
    //"mes:<signalId>:<yourId>:<myId>:<message>"
    NSString *mes = [NSString stringWithFormat:@"mes:%@:%@:%@:%@",@(self.signalId++),toId,self.identificationId,message];
    GNSMessage *pubMessage = [GNSMessage messageWithContent:[mes dataUsingEncoding:NSUTF8StringEncoding]];
    [self.publications addObject: [self.messageManager publicationWithMessage:pubMessage]];
    
    if(self.publications.count > saveNumberPublications) {
        [self.publications removeObjectAtIndex:0];
    }
}



@end
