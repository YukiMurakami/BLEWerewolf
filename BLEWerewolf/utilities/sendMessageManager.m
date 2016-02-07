//
//  sendMessageManager.m
//  NearByMessageChat
//
//  Created by Yuki Murakami on 2016/02/07.
//  Copyright © 2016年 yuki. All rights reserved.
//

/*
 
 NearbyMessageAPIでは、すべての近接する端末同士で相互通信が張られ、メッセージがブロードキャスト的な送信になってしまう。
 そこで相手との通信確立用の専用メッセージを設定し、それによって送信相手を取得し、その相手のIDと自分のIDをメッセージにのせて送受信することにする。
 
 "advertiseMyDevice:<myId>" 自分のIDを全員に知らせる (ペリフェラルのみ)
 （セントラルは個別に自分のIDを送る)
 "mes:<signalId>:<yourId>:<myId>:<message>" yourIDに対してメッセージを送信する
 送られるメッセージはすべて個別idを付与して送る（2重受信の防止)
 送り出すメッセージはその都度idをインクリメントする
 
 
 publishは配列にして５０個ほどは保存しておく（一斉送信など同時に複数のメッセージを送信する場合に必要）
 
 

*/

#import "sendMessageManager.h"
#import "BWUtility.h"
#import <GNSMessages.h>

static NSString * const APIKey = @"AIzaSyDWFBySXYZ_jYsfO67lvzVTmC4LAaCb8JU";

@interface sendMessageManager ()

@property (nonatomic) GNSPermission *nearbyPermission;
@property (nonatomic) GNSMessageManager *messageManager;
@property (nonatomic) NSMutableArray  *publications;
@property (nonatomic) id<GNSSubscription> subscription;
@property (nonatomic) NSString *identificationId;
@property (nonatomic) NSInteger signalId;
@property (nonatomic) NSMutableArray *receivedSignalIds;

@property (nonatomic) BOOL isPeripheral;
@property (nonatomic) NSMutableArray *centralIds;
@property (nonatomic) NSString *peripheralId;

@end

@implementation sendMessageManager

static sendMessageManager *sharedInstance = nil;

#pragma mark - Singleton
+ (instancetype)sharedInstance {
    @synchronized(self) {
        if(!sharedInstance) {
            sharedInstance = [[sendMessageManager alloc]initSharedInstance];
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

- (void)setIsPeripheral:(BOOL)isPeripheral {
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
    //デバイスのアドバータイズなら受け取る
    //"advertiseMyDevice:<myId>"
    if([[BWUtility getCommand:mes] isEqualToString:@"advertiseMyDevice"]) {
        NSArray *array = [mes componentsSeparatedByString:@":"];
        NSString *identificationId = array[1];
        [self.delegate didReceiveAdvertiseDevice:identificationId];
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
        if([receiverId isEqualToString:self.identificationId] && ![self.receivedSignalIds containsObject:@(signalId)]) {
            [self.delegate didReceiveMessage:message senderId:senderId];
            [self.receivedSignalIds addObject:@(signalId)];
        }
    }
}

#pragma mark - public methods

- (void)setPeripheralId:(NSString *)peripheralId {
    self.peripheralId = peripheralId;
}

- (BOOL)addCentralIdsObject:(NSString*)centralId {
    if(![self.centralIds containsObject:centralId]) {
        [self.centralIds addObject:centralId];
        return YES;
    }
    return NO;
}

- (void)sendMyIdentificationId {
    //"advertiseMyDevice:<myId>"
    NSString *mes = [NSString stringWithFormat:@"advertiseMyDevice:%@",self.identificationId];
    GNSMessage *pubMessage = [GNSMessage messageWithContent:[mes dataUsingEncoding:NSUTF8StringEncoding]];
    [self.publications addObject: [self.messageManager publicationWithMessage:pubMessage]];
    
    if(self.publications.count > 50) {
        [self.publications removeObjectAtIndex:0];
    }
}

- (void)sendMessageForPeripheral:(NSString*)message {
    [self sendMessageWithAddressId:message toId:self.peripheralId];
}

- (void)sendMessageForAllCentrals:(NSString*)message {
    for(NSInteger i=0;i<self.centralIds.count;i++) {
        [self sendMessageWithAddressId:message toId:self.centralIds[i]];
    }
}

- (void)sendMessageWithAddressId:(NSString*)message toId:(NSString*)toId {
    //"mes:<signalId>:<yourId>:<myId>:<message>"
    NSString *mes = [NSString stringWithFormat:@"mes:%@:%@:%@:%@",@(self.signalId++),toId,self.identificationId,message];
    GNSMessage *pubMessage = [GNSMessage messageWithContent:[mes dataUsingEncoding:NSUTF8StringEncoding]];
    [self.publications addObject: [self.messageManager publicationWithMessage:pubMessage]];
    
    if(self.publications.count > 50) {
        [self.publications removeObjectAtIndex:0];
    }
}



@end
