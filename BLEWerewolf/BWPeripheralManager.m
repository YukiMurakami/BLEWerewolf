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


@interface BWPeripheralManager () 

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

- (void)updateSendMessage :(NSString*)sendMessage {
    
    NSData *data = [sendMessage dataUsingEncoding:NSUTF8StringEncoding];
    if([self.peripheralManager updateValue:data forCharacteristic:self.characteristic onSubscribedCentrals:nil]) {
        NSLog(@"特性値更新");
    }
}

- (id)initSharedInstance {
    self = [super init];
    if (self) {
        // 初期化処理
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
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
        [_delegate didReceiveMessage:message];
    }
    
    [self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
}


@end
