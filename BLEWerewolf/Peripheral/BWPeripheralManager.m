//
//  BWPeripheralManager.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWPeripheralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"
#import "NSObject+BlocksWait.h"
#import "BWAppDelegate.h"
#import "BWUtility.h"
#import "BWViewController.h"
#import "BWSenderNode.h"






@interface BWPeripheralManager () {
    NSInteger signalId;
    
    NSMutableArray *signals;
    
    SKScene *scene;
    
    NSString *gameIdString;
    
    NSMutableArray *receivedSignalIds;//ペリフェラル側は受信したsinglaIdとidentificationIdとセットで区別する
    NSMutableArray *receivedReceiveNotifyIds;//受信通知signalIdを保存
    
    NSInteger synchronizeSignalId;//すべてのメッセージの受信チェックが必要な信号セットのID
    NSMutableArray *synchronizeSignalArray;//信号セットの情報を保存する配列
}

@end

@implementation BWPeripheralManager
@synthesize delegate = _delegate;

static BWPeripheralManager *sharedInstance = nil;

#pragma mark - Singleton
+ (instancetype)sharedInstance
{
    @synchronized(self) {
        if(!sharedInstance) {
            sharedInstance = [[BWPeripheralManager alloc] initSharedInstance];
        }
    }

    return sharedInstance;
}

- (void)setScene:(SKScene*)_scene {
    scene = _scene;
}

- (NSString*)getGameId {
    return gameIdString;
}

- (NSInteger)sendGlobalSignalMessage:(NSString*)message interval:(double)intervalTime {
    NSInteger _signalId = signalId;
    signalId++;
    
    if([[BWUtility getCommand:message] isEqualToString:@"serveId"]) {
        gameIdString = [BWUtility getCommandContents:message][0];
        //ここでゲームIDを確定させる
    }
    
    BWSenderNode *senderNode = [[BWSenderNode alloc]init];
    senderNode.signalId = _signalId;
    senderNode.signalKind = SignalKindGlobal;
    senderNode.firstSendDate = [NSDate date];
    senderNode.timeOutSeconds = 100000;
    senderNode.message = message;
    senderNode.isReceived = NO;
    senderNode.name = @"senderNode";
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *send = [SKAction runBlock:^{
        //「0:message」
        [self updateSendMessage:[NSString stringWithFormat:@"%d:%@",(int)senderNode.signalKind,senderNode.message]];
        BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
        [viewController addSendMessage:senderNode.message];
    }];
    
    BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
    [viewController.sceneForSenderNodes addChild:senderNode];
    
    SKAction *repeat = [SKAction repeatActionForever:[SKAction sequence:@[send,wait]]];
    senderNode.runningAction = repeat;
    [senderNode runAction:repeat];
    
    return _signalId;
}

- (void)stopGlobalSignal:(NSInteger)_signalId {
    BWSenderNode *senderNode = [self getSenderNodeWithSignalId:_signalId];
    if(senderNode.signalKind == SignalKindGlobal) {
        [senderNode removeAllActions];
        [senderNode removeFromParent];
        //[signals removeObject:senderNode];
    }
}

- (NSInteger)sendNormalMessage:(NSString*)message toIdentificationId:(NSString*)toIdentificationId interval:(double)intervalTime timeOut:(double)timeOut firstWait:(double)firstWait {
    NSInteger _signalId = signalId;
    signalId++;
    
    BWSenderNode *senderNode = [[BWSenderNode alloc]init];
    senderNode.signalId = _signalId;
    senderNode.signalKind = SignalKindNormal;
    senderNode.firstSendDate = [NSDate dateWithTimeIntervalSinceNow:firstWait];
    senderNode.timeOutSeconds = timeOut;
    senderNode.message = message;
    senderNode.isReceived = NO;
    senderNode.toIdentificationId = toIdentificationId;
    senderNode.name = @"senderNode";
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *firstWaitAction = [SKAction waitForDuration:firstWait];
    SKAction *send = [SKAction runBlock:^{
        //「1:NNNNNN:T..T:A..A:message」
        if([gameIdString isEqualToString:@""]) exit(0);
        NSString *sendMessage = [NSString stringWithFormat:@"%d:%@:%d:%@:%@",(int)senderNode.signalKind,gameIdString,(int)senderNode.signalId,senderNode.toIdentificationId,senderNode.message];
        [self updateSendMessage:sendMessage];
        BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
        [viewController addSendMessage:senderNode.message];
        
        NSDate *now = [NSDate date];
        NSDate *finishDate = [senderNode.firstSendDate dateByAddingTimeInterval:senderNode.timeOutSeconds];
        NSComparisonResult result = [now compare:finishDate];
        if(result == NSOrderedDescending || senderNode.isReceived) {
            [senderNode removeFromParent];
            //[signals removeObject:senderNode];
        }
    }];
    
    BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
    [viewController.sceneForSenderNodes addChild:senderNode];
    
    SKAction *repeat = [SKAction sequence:@[firstWaitAction,[SKAction repeatActionForever:[SKAction sequence:@[send,wait]]]]];
    senderNode.runningAction = repeat;
    [senderNode runAction:repeat];
    
    return _signalId;
}

- (void)sendNormalMessageEveryClient:(NSString*)message infoDic:(NSMutableDictionary*)infoDic interval:(double)intervalTime timeOut:(double)timeOut {
    
    NSMutableArray *players = infoDic[@"players"];
    for(NSInteger i=0;i<players.count;i++) {
        NSString *identificationId = players[i][@"identificationId"];
        if([identificationId isEqualToString:[BWUtility getIdentificationString]]) continue;
        //peripheral自信には送信しない
        [self sendNormalMessage:message toIdentificationId:identificationId interval:intervalTime timeOut:timeOut firstWait:0.05*i];
    }
    
}

- (NSInteger)sendNeedSynchronizeMessage:(NSMutableArray*)messageAndIdentificationId {
    NSInteger _synchronizeSignalId = synchronizeSignalId;
    synchronizeSignalId++;
    
    double intervalTime = 5.0;
    double timeOut = 1000.0;
    
    NSMutableArray *ids = [NSMutableArray array];
    for(NSInteger i=0;i<messageAndIdentificationId.count;i++) {
        NSString *message = messageAndIdentificationId[i][@"message"];
        NSString *identificationId = messageAndIdentificationId[i][@"identificationId"];
        
        NSInteger sendSignalId = [self sendNormalMessage:message toIdentificationId:identificationId interval:intervalTime timeOut:timeOut firstWait:0.05*i];
        [ids addObject:@(sendSignalId)];
    }
    
    [synchronizeSignalArray addObject:[@{@"ids":ids,@"id":@(_synchronizeSignalId),@"isAllOk":@NO}mutableCopy]];
    
    if(messageAndIdentificationId.count == 0) {
        [NSObject performBlock:^{
            [_delegate gotAllReceiveMessage:_synchronizeSignalId];
        } afterDelay:3.0];
    }
    
    return _synchronizeSignalId;
}

- (void)checkSynchronizeMessageReceive {
    //これを呼ぶと、受信通知状況をチェックして、すべて受信されていたらデリゲートを呼ぶ
    for(NSInteger i=0;i<synchronizeSignalArray.count;i++) {
        if([synchronizeSignalArray[i][@"isAllOk"]boolValue]) continue;
        NSArray *ids = synchronizeSignalArray[i][@"ids"];
        NSInteger id = [synchronizeSignalArray[i][@"id"]integerValue];
        BOOL isAllReceived = YES;
        NSString *debug = @"";
        for(NSInteger j=0;j<ids.count;j++) {
            BWSenderNode *node = [self getSenderNodeWithSignalId:[ids[j]integerValue]];
            debug = [NSString stringWithFormat:@"%@%@(%@,%d)",node,debug,ids[j],node.isReceived];
            if(!node.isReceived) {
                isAllReceived = NO;
            }
        }
        NSLog(@"%@",debug);
        if(isAllReceived) {
            [synchronizeSignalArray[i] setObject:@YES forKey:@"isAllOk"];
            [_delegate gotAllReceiveMessage:id];
        }
    }
}


-(void)sendReceivedMessage:(NSInteger)receivedSignalId identificationId:(NSString*)identificationId {
    double timeOut = 15.0;
    double intervalTime = 5.0;
    
    BWSenderNode *senderNode = [[BWSenderNode alloc]init];
    senderNode.signalId = -1;
    senderNode.signalKind = SignalKindReceived;
    senderNode.firstSendDate = [NSDate date];
    senderNode.timeOutSeconds = timeOut;
    senderNode.isReceived = NO;
    senderNode.toIdentificationId = identificationId;
    senderNode.name = @"senderNode";
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *send = [SKAction runBlock:^{
        //「2:NNNNNN:T..T:A..A」
        if([gameIdString isEqualToString:@""]) exit(0);
        NSString *sendMessage = [NSString stringWithFormat:@"%d:%@:%d:%@",(int)senderNode.signalKind,gameIdString,(int)receivedSignalId,senderNode.toIdentificationId];
        [self updateSendMessage:sendMessage];
        BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
        [viewController addSendMessage:sendMessage];
        
        NSDate *now = [NSDate date];
        NSDate *finishDate = [senderNode.firstSendDate dateByAddingTimeInterval:senderNode.timeOutSeconds];
        NSComparisonResult result = [now compare:finishDate];
        if(result == NSOrderedDescending) {
            [senderNode removeFromParent];
            //[signals removeObject:senderNode];
        }
    }];
    
    BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
    [viewController.sceneForSenderNodes addChild:senderNode];
    
    SKAction *repeat = [SKAction repeatActionForever:[SKAction sequence:@[send,wait]]];
    senderNode.runningAction = repeat;
    [senderNode runAction:repeat];
}

- (BWSenderNode*)getSenderNodeWithSignalId:(NSInteger)_signalId {
    BWSenderNode *node;
    for(NSInteger i=0;i<signals.count;i++) {
        if(((BWSenderNode*)signals[i]).signalId == _signalId) {
            node = signals[i];
            break;
        }
    }
    return node;
}


- (void)updateSendMessage :(NSString*)sendMessage {
    [sendingMessageQueue addObject:sendMessage];
    NSData *data = [sendMessage dataUsingEncoding:NSUTF8StringEncoding];
    if(!self.characteristic) return;
    if([self.peripheralManager updateValue:data forCharacteristic:self.characteristic onSubscribedCentrals:nil]) {
        NSLog(@"特性値更新:%@",sendingMessageQueue[0]);
        [sendingMessageQueue removeObjectAtIndex:0];
    }
}

- (id)initSharedInstance {
    self = [super init];
    if (self) {
        // 初期化処理
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
        sendingMessageQueue = [NSMutableArray array];
        
        signalId = 0;
        signals = [NSMutableArray array];
        receivedSignalIds = [NSMutableArray array];
        synchronizeSignalArray = [NSMutableArray array];
        receivedReceiveNotifyIds = [NSMutableArray array];
    }
    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)stopAllSignals {
    for(NSInteger i=0;i<signals.count;i++) {
        BWSenderNode *node = signals[i];
        [node removeAllActions];
        if(node.parent) {
            [node removeFromParent];
        }
    }
    [signals removeAllObjects];
}

+ (void)resetSharedInstance {
    sharedInstance.peripheralManager = nil;
    sharedInstance = nil;
}


- (void)setupService
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // Creates the characteristic UUID
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID];
    NSLog(@"[characteristicUUID.description] %@", characteristicUUID.description);
    
    // Creates the characteristic
    //self.characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    //NSString *sendMessage = @"first_message";
    //NSData *data = [sendMessage dataUsingEncoding:NSUTF8StringEncoding];
    
    //self.characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:(CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify | CBCharacteristicPropertyWrite) value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable | CBAttributePermissionsWriteEncryptionRequired];
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:(CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify | CBCharacteristicPropertyWriteWithoutResponse | CBCharacteristicPropertyWrite) value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable | CBAttributePermissionsWriteEncryptionRequired];
    
    
    // Creates the service UUID
    CBUUID *serviceUUID = [CBUUID UUIDWithString:TRANSFER_SERVICE_UUID];
    
    // Creates the service and adds the characteristic to it
    self.service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    
    // Sets the characteristics for this service
    [self.service setCharacteristics:@[self.characteristic]];
    
    // Publishes the service
    [self.peripheralManager addService:self.service];
}


// ------------------------------
// CBPeripheralManagerDelegate
// ------------------------------

// Monitoring Changes to the Peripheral Manager’s State

// CBPeripheralManager が初期化されたり状態が変化した際に呼ばれるデリゲートメソッド
// peripheralManagerDidUpdateState:
// Invoked when the peripheral manager's state is updated. (required)
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"%d, CBPeripheralManagerStatePoweredOn", (int)peripheral.state);
            // PowerOn なら，デバイスのセッティングを開始する．
            [self setupService];
            break;
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"%d, CBPeripheralManagerStatePoweredOn", (int)peripheral.state);
            break;
        case CBPeripheralManagerStateResetting:
            NSLog(@"%d, CBPeripheralManagerStatePoweredOn", (int)peripheral.state);
            break;
        case CBPeripheralManagerStateUnauthorized:
            NSLog(@"%d, CBPeripheralManagerStatePoweredOn", (int)peripheral.state);
            break;
        case CBPeripheralManagerStateUnsupported:
            NSLog(@"%d, CBPeripheralManagerStatePoweredOn", (int)peripheral.state);
            break;
        case CBPeripheralManagerStateUnknown:
            NSLog(@"%d, CBPeripheralManagerStatePoweredOn", (int)peripheral.state);
            break;
        default:
            break;
    }
}

// peripheralManager:willRestoreState:
// Invoked when the peripheral manager is about to be restored by the system.
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// Adding Services

// peripheralManager:didAddService:error:
// Invoked when you publish a service, and any of its associated characteristics and characteristic descriptors, to the local Generic Attribute Profile (GATT) database.
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    if(error){
        NSLog(@"[error] %@", [error localizedDescription]);
    }else{
        // Starts advertising the service
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey : @"mokyu", CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
        NSLog(@"start advertising");
        
    }
}

// Advertising Peripheral Data

// peripheralManagerDidStartAdvertising:error:
// Invoked when you start advertising the local peripheral device’s data.
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if(error){
        NSLog(@"[error] %@", [error localizedDescription]);
    }else{
        NSLog(@"no error");
    }
}

// Monitoring Subscriptions to Characteristic Values

// peripheralManager:central:didSubscribeToCharacteristic:
// Invoked when a remote central device subscribes to a characteristic’s value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// peripheralManager:central:didUnsubscribeFromCharacteristic:
// Invoked when a remote central device unsubscribes from a characteristic’s value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// peripheralManagerIsReadyToUpdateSubscribers:
// Invoked when a local peripheral device is again ready to send characteristic value updates. (required)
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    [NSObject performBlock:^{
        NSData *data = [sendingMessageQueue[0] dataUsingEncoding:NSUTF8StringEncoding];
        if([self.peripheralManager updateValue:data forCharacteristic:self.characteristic onSubscribedCentrals:nil]) {
            NSLog(@"特性値更新:%@",sendingMessageQueue[0]);
            [sendingMessageQueue removeObjectAtIndex:0];
        }
    } afterDelay:0.05];
    
    
}

// Receiving Read and Write Requests

// peripheralManager:didReceiveReadRequest:
// Invoked when a local peripheral device receives an Attribute Protocol (ATT) read request for a characteristic that has a dynamic value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// peripheralManager:didReceiveWriteRequests:
// Invoked when a local peripheral device receives an Attribute Protocol (ATT) write request for a characteristic that has a dynamic value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"request:%@",requests);
    
    for(CBATTRequest *request in requests) {
        NSString *message = [[NSString alloc]initWithData:request.value encoding:NSUTF8StringEncoding];
        NSLog(@"written data:%@",message);
        
        //TODO::セントラルからの受信を処理
        //「1:NNNNNN:T..T:A..A:message」T..TはセントラルのシグナルID
        //「2:NNNNNN:T..T」T..Tは先ほどペリフェラルが送ったシグナルID
        NSString *contentMessage = @"";
        SignalKind kind = [[BWUtility getCommand:message]integerValue];
        if(kind == SignalKindReceived) {
            //「2:NNNNNN:T..T」
            NSString *gotGameId = [message componentsSeparatedByString:@":"][1];
            NSInteger gotSignalId = [[message componentsSeparatedByString:@":"][2]integerValue];
            if([gotGameId isEqualToString:gameIdString]) {
                if([receivedReceiveNotifyIds containsObject:@(gotSignalId)]) {
                    return;//２重受信を防ぐ
                }
                [receivedReceiveNotifyIds addObject:@(gotSignalId)];
                BWSenderNode *node = [self getSenderNodeWithSignalId:gotSignalId];
                node.isReceived = YES;
                
                BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
                [viewController addRecieveMessage:message];
                
                [self checkSynchronizeMessageReceive];
            }
        }
        if(kind == SignalKindNormal) {
            //「1:NNNNNN:T..T:A..A:message」
            NSArray *array = [message componentsSeparatedByString:@":"];
            NSString *gotGameId = array[1];
            NSInteger gotSignalId = [array[2]integerValue];
            NSString *identificationId = array[3];
            
            if([receivedSignalIds containsObject:[NSString stringWithFormat:@"%@-%d",identificationId,(int)gotSignalId]]) {
                return;//２重受信を防ぐ
            }
            [receivedSignalIds addObject:[NSString stringWithFormat:@"%@-%d",identificationId,(int)gotSignalId]];
            
            
            if([gameIdString isEqualToString:gotGameId]) {
                BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
                [viewController addRecieveMessage:message];
                //受信
                for(NSInteger i=4;i<array.count;i++) {
                    if(i == 4) {
                        contentMessage = [NSString stringWithFormat:@"%@%@",contentMessage,array[i]];
                    } else {
                        contentMessage = [NSString stringWithFormat:@"%@:%@",contentMessage,array[i]];
                    }
                }
                [_delegate didReceiveMessage:contentMessage];
                
                //受信完了通知を返す
                [self sendReceivedMessage:gotSignalId identificationId:identificationId];
            }
        }
    }
    
    [self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
}


@end
