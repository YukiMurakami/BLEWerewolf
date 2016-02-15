//
//  BWSocketManager.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/02/15.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWSocketManager.h"

/*
 ソケット通信のブロードキャスト送信をメッセージ送受信に利用する。
 そ相手との通信確立用の専用メッセージを設定し、それによって送信相手を取得し、その相手のIDと自分のIDをメッセージにのせて送受信することにする。
 
 "advertiseMyDevice:<gameId>:<peripheralId>:<peripheralName>" 自分のIDを不特定多数の全員に知らせる (ペリフェラルのみ）
 （セントラルは個別に自分のIDを送る)
 "mes:<signalId>:<yourId>:<myId>:<message>" yourIDに対してメッセージを送信する
 送られるメッセージはすべて個別idを付与して送る（2重受信の防止)
 送り出すメッセージはその都度idをインクリメントする
 */

#import "BWUtility.h"
#import "NSObject+BlocksWait.h"

#import "BWViewController.h"
#import "BWAppDelegate.h"

#import "SocketIOPacket.h"

NSString const *IPAddress = @"133.11.238.87";
NSInteger const port = 3000;

@interface BWSocketManager ()

@property (strong, nonatomic) SocketIO *socketIO;

@property (nonatomic) NSString *identificationId;
@property (nonatomic) NSInteger signalId;
@property (nonatomic) NSMutableArray *receivedSignalIds;
@property (nonatomic) NSMutableArray *centralIds;
@property (nonatomic) NSString *peripheralId;

@end

@implementation BWSocketManager

static BWSocketManager *sharedInstance = nil;

#pragma mark - Singleton
+ (instancetype)sharedInstance {
    @synchronized(self) {
        if(!sharedInstance) {
            sharedInstance = [[BWSocketManager alloc]initSharedInstance];
        }
    }
    return sharedInstance;
}

+ (void)resetSharedInstance {
    [sharedInstance disconnect];
    sharedInstance = nil;
}

- (void)connect
{
    if(!self.socketIO.isConnected && !self.socketIO.isConnecting) {
        [self.socketIO connectToHost:IPAddress onPort:port];
    }
}

- (void)disconnect
{
    [self.socketIO disconnect];
}

- (id)initSharedInstance {
    self = [super init];
    if(self) {
        //初期化処理
        self.identificationId = [BWUtility getIdentificationString];
        self.signalId = arc4random_uniform(1000000);
        self.receivedSignalIds = [NSMutableArray array];
        
        self.socketIO = [[SocketIO alloc] initWithDelegate:self];
        [self connect];
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
        
        BOOL canReceive = NO;
        
        if(self.isPeripheral) {
            //ペリフェラルは担当セントラルからのメッセージのみ受信
            //ただしparticipateRequestだけは無条件で受信
            if([receiverId isEqualToString:self.identificationId]) {//自分あてかどうか確認
                if([self.centralIds containsObject:senderId] || [array[4] isEqualToString:@"participateRequest"]) {
                    canReceive = YES;
                }
            }
        } else {
            //セントラルは自分のペリフェラルからのメッセージのみ受信
            if([receiverId isEqualToString:self.identificationId] || [receiverId isEqualToString:@"centrals"]) {//自分あてかどうか確認 centralsならすべて受信（セントラルへのブロードキャスト）
                if([senderId isEqualToString:self.peripheralId]) {
                    canReceive = YES;
                }
            }
        }
        if(![self.receivedSignalIds containsObject:@(signalId)] && canReceive) {
            [self.delegate didReceiveMessage:message senderId:senderId];
            [self.receivedSignalIds addObject:@(signalId)];
        }
    }
}

#pragma mark - socketDelegate
- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    if ([packet.name isEqualToString:@"message:receive"]) {
        // メッセージが空でなければ受信
        [self receiveMessage:packet.args[0][@"message"]];
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

- (void)startAdvertiseGameRoomInfo:(NSString*)gameIdString {//only peripheral
    //"advertiseMyDevice:<gameId>:<peripheralId>:<peripheralName>" 自分のIDを不特定多数の全員に知らせる (ペリフェラルのみ）
    NSString *mes = [NSString stringWithFormat:@"advertiseMyDevice:%@:%@:%@",gameIdString,self.identificationId,[BWUtility getUserName]];
    
    [self.socketIO sendEvent:@"message:send" withData:@{@"message" : mes}];
}

- (void)sendMessageForPeripheral:(NSString*)message {
    [self sendMessageWithAddressId:message toId:self.peripheralId];
}

- (void)sendMessageForAllCentrals:(NSString*)message {
    [self sendMessageWithAddressId:message toId:@"centrals"];
}

- (void)sendMessageWithAddressId:(NSString*)message toId:(NSString*)toId {// periphral or central
    //"mes:<signalId>:<yourId>:<myId>:<message>"
    NSString *mes = [NSString stringWithFormat:@"mes:%@:%@:%@:%@",@(self.signalId++),toId,self.identificationId,message];
    
    [self.socketIO sendEvent:@"message:send" withData:@{@"message" : mes}];
}

@end