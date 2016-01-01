//
//  BWCentralManager.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/28.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BWCentralManagerDelegate
- (void)didReceivedMessage:(NSString*)message;
@end

@interface BWCentralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    id<BWCentralManagerDelegate> _delegate;
}

@property (nonatomic) id<BWCentralManagerDelegate> delegate;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBCharacteristic *interestingCharacteristic;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableData *data;

+ (instancetype)sharedInstance;
-(void)sendMessageFromClient:(NSString*)message;

// --------------------------------
// CBCentralManagerDelegate
// --------------------------------

// Monitoring Connections with Peripherals

// Invoked when a connection is successfully created with a peripheral.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(nonnull CBPeripheral *)peripheral;

// Invoked when an existing connection with a peripheral is torn down.
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error;

// Invoked when the central manager fails to create a connection with a peripheral
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error;


// Discovering and Retrieving Peripherals

// Invoked when the central manager discovers a peripheral while scanning.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI;

// Invoked when the central manager retrieves a list of peripherals connected to the system.
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals;

// Invoked when the central manager retrieves a list of known peripherals.
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals;

// Monitring Changes to the Central Manager's State

// Invoked when the central manager's state is updated. (required)
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;

// Invoked when the central manager is about to be restored by the system.
- (void)centralManager:(CBCentralManager *)central willRestoreState:(nonnull NSDictionary *)dict;



// -------------------------
// CBPeripheral Delegate
// -------------------------

//Discovering Services

// Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error;

// Invoked when you discover the included services of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(nonnull CBService *)service error:(nullable NSError *)error;

// Discovering Characteristics and Characteristic Descriptors

// Invoked when you discover the characteristics of a pecified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error;

// Invoked when you discover the descriptors of a specified characteristic.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error;

// Retrieving Characteristic and Characteristic Descriptor Values

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error;

// Invoked when you retrieve a specified characteristic descriptor's value
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(nonnull CBDescriptor *)descriptor error:(nullable NSError *)error;

// Writing Characteristic and Characteristic Descriptor Values

// Invoked when you write data to a characteristic's value.
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error;

// Invoked when you write data to a characteristic descriptor's value
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(nonnull CBDescriptor *)descriptor error:(nullable NSError *)error;

// Managing Notifications for a Characteristic's Value

// Invoked when the peripheral receives a request to start or stop provoding notifications for a specified characterstic's value.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error;

// Retrieving a Peripheral's Received Signal Strength Indicator (RSSI) Data

// Invoked when you retrieve the value of the peripheral's current RSSI while it is connected to the central manager.
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error;

// Monitoring Changes to a Peripheral's Name or Services

// Invoked when a peripheral's name changes.
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral;

// Invoked when a peripheral's services have changed.
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices;


@end
