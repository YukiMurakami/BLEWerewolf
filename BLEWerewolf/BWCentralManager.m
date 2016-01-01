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



@interface BWCentralManager ()


@end



@implementation BWCentralManager
@synthesize delegate = _delegate;

#pragma mark - Singleton
+ (instancetype)sharedInstance
{
    static BWCentralManager *sharedInstance = nil;
    
    static dispatch_once_t once;
    dispatch_once( &once, ^{
        sharedInstance = [[BWCentralManager alloc] init];
        
        sharedInstance.centralManager = [[CBCentralManager alloc] initWithDelegate:sharedInstance queue:nil];
    
        sharedInstance.data = [[NSMutableData alloc] init];
    });
    
    return sharedInstance;
}

-(void)sendMessageFromClient:(NSString*)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"send message :%@",message);
    [self.peripheral writeValue:data forCharacteristic:self.interestingCharacteristic type:CBCharacteristicWriteWithResponse];
    
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
        
        [_delegate didReceivedMessage:receivedString];
        
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