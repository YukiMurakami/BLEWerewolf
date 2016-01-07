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
#import "BWSenderNode.h"






@interface BWPeripheralManager () {
    NSInteger signalId;
    
    NSMutableArray *signals;
    
    SKScene *scene;
    
    NSString *gameIdString;
}

@end

@implementation BWPeripheralManager
@synthesize delegate = _delegate;

#pragma mark - Singleton
+ (instancetype)sharedInstance
{
    static BWPeripheralManager *sharedInstance = nil;

    static dispatch_once_t once;
    dispatch_once( &once, ^{
        sharedInstance = [[BWPeripheralManager alloc] initSharedInstance];
        
    });

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
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *send = [SKAction runBlock:^{
        //「0:message」
        [self updateSendMessage:[NSString stringWithFormat:@"%d:%@",(int)senderNode.signalKind,senderNode.message]];
    }];
    
    [(SKScene*)self.delegate addChild:senderNode];
    
    SKAction *repeat = [SKAction repeatActionForever:[SKAction sequence:@[wait,send]]];
    [senderNode runAction:repeat];
    
    return _signalId;
}

- (void)stopGlobalSignal:(NSInteger)_signalId {
    BWSenderNode *senderNode = [self getSenderNodeWithSignalId:_signalId];
    if(senderNode.signalKind == SignalKindGlobal) {
        [senderNode removeAllActions];
        [senderNode removeFromParent];
        [signals removeObject:senderNode];
    }
}

- (NSInteger)sendNormalMessage:(NSString*)message toIdentificationId:(NSString*)toIdentificationId interval:(double)intervalTime timeOut:(double)timeOut {
    NSInteger _signalId = signalId;
    signalId++;
    
    BWSenderNode *senderNode = [[BWSenderNode alloc]init];
    senderNode.signalId = _signalId;
    senderNode.signalKind = SignalKindNormal;
    senderNode.firstSendDate = [NSDate date];
    senderNode.timeOutSeconds = timeOut;
    senderNode.message = message;
    senderNode.isReceived = NO;
    senderNode.toIdentificationId = toIdentificationId;
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *send = [SKAction runBlock:^{
        //「1:NNNNNN:T..T:A..A:message」
        if([gameIdString isEqualToString:@""]) exit(0);
        NSString *sendMessage = [NSString stringWithFormat:@"%d:%@:%d:%@:%@",(int)senderNode.signalKind,gameIdString,(int)senderNode.signalId,senderNode.toIdentificationId,senderNode.message];
        [self updateSendMessage:sendMessage];
        
        NSDate *now = [NSDate date];
        NSDate *finishDate = [senderNode.firstSendDate dateByAddingTimeInterval:senderNode.timeOutSeconds];
        NSComparisonResult result = [now compare:finishDate];
        if(result == NSOrderedDescending || senderNode.isReceived) {
            [senderNode removeFromParent];
            [signals removeObject:senderNode];
        }
    }];
    
    [(SKScene*)self.delegate addChild:senderNode];
    
    SKAction *repeat = [SKAction repeatActionForever:[SKAction sequence:@[wait,send]]];
    [senderNode runAction:repeat];
    
    return _signalId;
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
    }
    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
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
    
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:(CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify | CBCharacteristicPropertyWrite) value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable | CBAttributePermissionsWriteEncryptionRequired];
    
    
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
    } afterDelay:0.01];
    
    
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
        SignalKind kind = [[BWUtility getCommand:message]integerValue];
        if(kind == SignalKindReceived) {
            //「2:NNNNNN:T..T」
            NSString *gotGameId = [message componentsSeparatedByString:@":"][1];
            NSInteger gotSignalId = [[message componentsSeparatedByString:@":"][2]integerValue];
            if([gotGameId isEqualToString:gameIdString]) {
                BWSenderNode *node = [self getSenderNodeWithSignalId:gotSignalId];
                node.isReceived = YES;
            }
        }
        if(kind == SignalKindNormal) {
            //「1:NNNNNN:T..T:A..A:message」
            [_delegate didReceiveMessage:message];
        }
    }
    
    [self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
}


@end
