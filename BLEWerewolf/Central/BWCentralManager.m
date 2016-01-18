//
//  BWCentralManager.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/28.
//  Copyright (c) 2015年 yuki. All rights reserved.
//



#import "BWCentralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "TransferService.h"
#import "BWUtility.h"

#import "BWSenderNode.h"

#import "BWViewController.h"
#import "BWAppDelegate.h"



@interface BWCentralManager () {
    NSString *gameIdString;
    
    NSMutableArray *signals;
    NSMutableArray *receivedSignalIds;
    NSInteger signalId;
}


@end



@implementation BWCentralManager
@synthesize delegate = _delegate;

static BWCentralManager *sharedInstance = nil;

#pragma mark - Singleton
+ (instancetype)sharedInstance
{
    @synchronized(self) {
        if(!sharedInstance) {
        
            sharedInstance = [[BWCentralManager alloc] initSharedInstance];
        
            sharedInstance.centralManager = [[CBCentralManager alloc] initWithDelegate:sharedInstance queue:nil];
    
            sharedInstance.data = [[NSMutableData alloc] init];
        }
    }
    
    return sharedInstance;
}


- (id)initSharedInstance {
    self = [super init];
    if (self) {
        // 初期化処理
        
        signalId = 0;
        signals = [NSMutableArray array];
        receivedSignalIds = [NSMutableArray array];
    }
    return self;
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
    sharedInstance.centralManager = nil;
    sharedInstance = nil;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (NSInteger)sendNormalMessage:(NSString*)message interval:(double)intervalTime timeOut:(double)timeOut firstWait:(double)firstWait {
    NSInteger _signalId = signalId;
    signalId++;
    
    BWSenderNode *senderNode = [[BWSenderNode alloc]init];
    senderNode.signalId = _signalId;
    senderNode.signalKind = SignalKindNormal;
    senderNode.firstSendDate = [NSDate dateWithTimeIntervalSinceNow:firstWait];
    senderNode.timeOutSeconds = timeOut;
    senderNode.message = message;
    senderNode.isReceived = NO;
    senderNode.name = @"senderNode";
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *firstWaitAction = [SKAction waitForDuration:firstWait];
    SKAction *send = [SKAction runBlock:^{
        // T..Tは自分のsignalID,A..Aは自分のidentificationID
        //「1:NNNNNN:T..T:C..C,P..P:message」C..Cは送り元 P..Pは送り先ペリフェラル
        if([gameIdString isEqualToString:@""]) exit(0);
        NSString *sendMessage = [NSString stringWithFormat:@"%d:%@:%d:%@:%@:%@",(int)senderNode.signalKind,gameIdString,(int)senderNode.signalId,[BWUtility getIdentificationString],[BWUtility getPeripheralIdentificationId],senderNode.message];
        NSString *command = [BWUtility getCommand:senderNode.message];
        //・ゲーム部屋に参加要求「participateRequest:NNNNNN/A..A/S...S/P..P/F」NNNNNNは６桁のゲームID、A..Aは16桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名,P..Pは接続先ペリフェラルID,Fは普通のセントラルなら0,サブサーバなら1
        if([command isEqualToString:@"participateRequest"]) {
            [self sendMessageFromClientWithResponse:sendMessage];
        } else {
            [self sendMessageFromClient:sendMessage];
        }
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


-(void)sendReceivedMessage:(NSInteger)receivedSignalId {
    double timeOut = 15.0;
    double intervalTime = 5.0;
    
    BWSenderNode *senderNode = [[BWSenderNode alloc]init];
    senderNode.signalId = -1;
    senderNode.signalKind = SignalKindReceived;
    senderNode.firstSendDate = [NSDate date];
    senderNode.timeOutSeconds = timeOut;
    senderNode.isReceived = NO;
    senderNode.name = @"senderNode";
    
    [signals addObject:senderNode];
    
    SKAction *wait = [SKAction waitForDuration:intervalTime];
    SKAction *send = [SKAction runBlock:^{
        //central「2:NNNNNN:T..T:C..C:P..P」(T..Tは受け取ったsignalId)
        if([gameIdString isEqualToString:@""]) exit(0);
        NSString *sendMessage = [NSString stringWithFormat:@"%d:%@:%d:%@:%@",(int)senderNode.signalKind,
                                 gameIdString,
                                 (int)receivedSignalId,
                                 [BWUtility getIdentificationString],
                                 [BWUtility getPeripheralIdentificationId]];
        [self sendMessageFromClient:sendMessage];
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

-(void)sendMessageFromClient:(NSString*)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"send message :%@",message);
    //[self.peripheral writeValue:data forCharacteristic:self.interestingCharacteristic type:CBCharacteristicWriteWithResponse];
    [self.peripheral writeValue:data forCharacteristic:self.interestingCharacteristic type:CBCharacteristicWriteWithoutResponse];
    
}

-(void)sendMessageFromClientWithResponse:(NSString*)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"send message withResponse :%@",message);
    [self.peripheral writeValue:data forCharacteristic:self.interestingCharacteristic type:CBCharacteristicWriteWithResponse];
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

-(NSString*)getGameId {
    return gameIdString;
}

-(void)setGameId :(NSString*)gameIdStr{
    gameIdString = gameIdStr;
}

-(void)stopScan {
    [self.centralManager stopScan];
}

// --------------------------------
// CBCentralManagerDelegate
// --------------------------------

// Monitoring Connections with Peripherals

// Invoked when a connection is successfully created with a peripheral.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(nonnull CBPeripheral *)peripheral
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    NSLog(@"%@",peripheral.description);
    
    // Clears the data that we may already have
    [self.data setLength:0];
    // Sets the peripheral delegate
    [self.peripheral setDelegate:self];
    // Asks the peripheral to discover the service
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

// Invoked when an existing connection with a peripheral is torn down.
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if(error) {
        NSLog(@"[error] %@",[error localizedDescription]);
        NSLog(@"[error] %@",[error localizedFailureReason]);
        NSLog(@"[error] %@",[error localizedRecoverySuggestion]);
    } else {
        NSLog(@"disconnect");
    }
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
}

// Invoked when the central manager fails to create a connection with a peripheral
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


// Discovering and Retrieving Peripherals

// デバイス発見時
// Invoked when the central manager discovers a peripheral while scanning.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [self.centralManager stopScan];
    NSLog(@"[RSSI] %@",RSSI);
    if(self.peripheral != peripheral) {
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        //発見されたデバイスに接続
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

// Invoked when the central manager retrieves a list of peripherals connected to the system.
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

// Invoked when the central manager retrieves a list of known peripherals.
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

// Monitring Changes to the Central Manager's State

// Invoked when the central manager's state is updated. (required)
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"%d, CBCentralManagerStatePoweredOn",(int)central.state);
            [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"%d, CBCentralManagerStatePoweredOff",(int)central.state);
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"%d, CBCentralManagerStateResetting", (int)central.state);
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"%d, CBCentralManagerUnauthorized", (int)central.state);
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"%d, CBCentralManagerStateUnsupported", (int)central.state);
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"%d, CBCentralManagerStateUnknown", (int)central.state);
            break;
        default:
            break;
    }
}

// Invoked when the central manager is about to be restored by the system.
- (void)centralManager:(CBCentralManager *)central willRestoreState:(nonnull NSDictionary *)dict
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}



// -------------------------
// CBPeripheral Delegate
// -------------------------

//Discovering Services

// Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if(error) {
        NSLog(@"[error] %@", [error localizedDescription]);
    } else {
        for(CBService *service in peripheral.services) {
            NSLog(@"Service found with UUID: %@",service.UUID);
            
            // Discovers the characteristics for a given service
            if([service.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]) {
                NSLog(@"discover characteristic!");
                [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
            }
        }
    }
}

// Invoked when you discover the included services of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(nonnull CBService *)service error:(nullable NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

// Discovering Characteristics and Characteristic Descriptors

// Invoked when you discover the characteristics of a pecified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if(error) {
        NSLog(@"[error] %@", [error localizedDescription]);
    } else {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]) {
            for(CBCharacteristic *characteristic in service.characteristics) {
                if([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                    NSLog(@"characteristics is found!");
                    self.interestingCharacteristic = characteristic;
                    [peripheral readValueForCharacteristic:characteristic];
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

// Invoked when you discover the descriptors of a specified characteristic.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// Retrieving Characteristic and Characteristic Descriptor Values

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if(error) {
        NSLog(@"[error] %@", [error localizedDescription]);
    } else {
        NSLog(@"no error");
        NSData *data = characteristic.value;
        
        NSString *receivedString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        NSLog(@"[data] %@",receivedString);
        
        
        
        //TODO::受信振り分け、受信完了通知が必要な場合は返す
        SignalKind kind = [[BWUtility getCommand:receivedString]integerValue];
        NSString *message = @"";
        if(kind == SignalKindGlobal) {
        //「0:message」
            message = [receivedString substringFromIndex:2];
            [_delegate didReceivedMessage:message];
            
            BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
            [viewController addRecieveMessage:receivedString];
        }
        if(kind == SignalKindReceived) {
            //peripheral「2:NNNNNN:T..T:C..C:P..P」(T..Tは受け取ったsignalId C..Cは受け取った識別ID)
            //セントラルからさっき送ったメッセージの受信通知をペリフェラルから受けとる
            NSString *gotGameId = [receivedString componentsSeparatedByString:@":"][1];
            NSInteger gotSignalId = [[receivedString componentsSeparatedByString:@":"][2]integerValue];
            NSString *identificationId = [receivedString componentsSeparatedByString:@":"][3];
            NSString *peripheralId = [receivedString componentsSeparatedByString:@":"][4];
            if([gotGameId isEqualToString:gameIdString] && [identificationId isEqualToString:[BWUtility getIdentificationString]] && [peripheralId isEqualToString:[BWUtility getPeripheralIdentificationId]]) {
                BWSenderNode *node = [self getSenderNodeWithSignalId:gotSignalId];
                node.isReceived = YES;
                
                BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
                [viewController addRecieveMessage:receivedString];
            }
            
            if([gotGameId isEqualToString:gameIdString] && [BWUtility isSubPeripheral] && [peripheralId isEqualToString:[BWUtility getPeripheralIdentificationId]] && [[BWUtility getCentralIdentifications] containsObject:identificationId] && [BWUtility isStartGameFlag]) {
                //サブサーバはセントラルへ中継する
                [_delegate didReceivedCentralReceiveMessage:receivedString];
            }
        }
        if(kind == SignalKindNormal) {
        //「1:NNNNNN:T..T:A..A:B..B:message」の形式で送信する（NNNNNNはゲームID,T..TはシグナルID,A..Aは送り先ID,B..Bは送り元）
            NSArray *array = [receivedString componentsSeparatedByString:@":"];
            
            NSString *peripheralId = array[4];
            /*
            if(!([peripheralId isEqualToString:[BWUtility getPeripheralIdentificationId]])) {
                return;//関係ないペリフェラルの信号は受信しない
            }
             */
             
            
            NSString *gotGameId = array[1];
            NSInteger gotSignalId = [array[2]integerValue];
            
            if([receivedSignalIds containsObject:@(gotSignalId)]) {
                return;//２重受信を防ぐ
            }
            [receivedSignalIds addObject:@(gotSignalId)];
            
            NSString *identificationId = array[3];
            if([identificationId isEqualToString:[BWUtility getIdentificationString]] && [gameIdString isEqualToString:gotGameId]) {
                
                BWAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
                [viewController addRecieveMessage:receivedString];
                //受信
                for(NSInteger i=5;i<array.count;i++) {
                    if(i == 5) {
                        message = [NSString stringWithFormat:@"%@%@",message,array[i]];
                    } else {
                        message = [NSString stringWithFormat:@"%@:%@",message,array[i]];
                    }
                }
                [_delegate didReceivedMessage:message];
                
                //受信完了通知を返す
                [self sendReceivedMessage:gotSignalId];
            }
            
            if([[BWUtility getCentralIdentifications] containsObject:identificationId] && [gameIdString isEqualToString:gotGameId] && [BWUtility isStartGameFlag]) {
                //サブサーバはさらにペリフェラルに中継する
                [_delegate didReceivedCentralReceiveMessage:receivedString];
            }
        }
        
        
    }
}

// Invoked when you retrieve a specified characteristic descriptor's value
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(nonnull CBDescriptor *)descriptor error:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// Writing Characteristic and Characteristic Descriptor Values

// Invoked when you write data to a characteristic's value.
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"Did write characteristic value : %@ with ID %@", characteristic.value, characteristic.UUID);
    if (error) {
        NSLog(@"Error writing characteristic value: %@",[error localizedDescription]);
    } else {
        NSLog(@"Successful writing !!!!!!!!!!!!!!!!!");
    }
}

// Invoked when you write data to a characteristic descriptor's value
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(nonnull CBDescriptor *)descriptor error:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// Managing Notifications for a Characteristic's Value

// Invoked when the peripheral receives a request to start or stop provoding notifications for a specified characterstic's value.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if(error) {
        NSLog(@"[error] %@", [error localizedDescription]);
    } else {
        // Exits if it's not the transfer characteristic
        if(![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            return;
        }
        
        // Notification has started
        if(characteristic.isNotifying) {
            NSLog(@"Notification began on %@", characteristic);
            [peripheral readValueForCharacteristic:characteristic];
        } else {// Notification has stopped
            // so disconnect from the peripheral
            NSLog(@"Notification stopped on %@. Disconncting", characteristic);
            [self.centralManager cancelPeripheralConnection:self.peripheral];
        }
    }
}

// Retrieving a Peripheral's Received Signal Strength Indicator (RSSI) Data

// Invoked when you retrieve the value of the peripheral's current RSSI while it is connected to the central manager.
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// Monitoring Changes to a Peripheral's Name or Services

// Invoked when a peripheral's name changes.
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

// Invoked when a peripheral's services have changed.
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


@end