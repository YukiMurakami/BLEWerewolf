//
//  BWPeripheralManager.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <SpriteKit/SpriteKit.h>

@protocol BWPeripheralManagerDelegate
-(void)didReceiveMessage:(NSString*)message;
-(void)gotAllReceiveMessage:(NSInteger)id;
@end

@interface BWPeripheralManager : NSObject <CBPeripheralManagerDelegate> {
    id<BWPeripheralManagerDelegate> _delegate;
    
    NSMutableArray *sendingMessageQueue;
}

@property (nonatomic) id<BWPeripheralManagerDelegate> delegate;

+ (instancetype)sharedInstance;
+ (void)resetSharedInstance;
- (void)stopAllSignals;
- (void)setScene:(SKScene*)_scene;

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, strong) CBMutableService *service;



- (NSString*)getGameId;
- (NSInteger)sendGlobalSignalMessage:(NSString*)message interval:(double)intervalTime;
- (void)stopGlobalSignal:(NSInteger)_signalId;
- (NSInteger)sendNormalMessage:(NSString*)message toIdentificationId:(NSString*)toIdentificationId interval:(double)intervalTime timeOut:(double)timeOut firstWait:(double)firstWait;
- (void)sendNormalMessageEveryClient:(NSString*)message infoDic:(NSMutableDictionary*)infoDic interval:(double)intervalTime timeOut:(double)timeOut;
- (NSInteger)sendNeedSynchronizeMessage:(NSMutableArray*)messageAndIdentificationId;
- (void)stopAd;

// ------------------------------
// CBPeripheralManagerDelegate
// ------------------------------

// Monitoring Changes to the Peripheral Manager’s State

// peripheralManagerDidUpdateState:
// Invoked when the peripheral manager's state is updated. (required)
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral;

// peripheralManager:willRestoreState:
// Invoked when the peripheral manager is about to be restored by the system.
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict;

// Adding Services

// peripheralManager:didAddService:error:
// Invoked when you publish a service, and any of its associated characteristics and characteristic descriptors, to the local Generic Attribute Profile (GATT) database.
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error;

// Advertising Peripheral Data

// peripheralManagerDidStartAdvertising:error:
// Invoked when you start advertising the local peripheral device’s data.
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error;

// Monitoring Subscriptions to Characteristic Values

// peripheralManager:central:didSubscribeToCharacteristic:
// Invoked when a remote central device subscribes to a characteristic’s value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic;

// peripheralManager:central:didUnsubscribeFromCharacteristic:
// Invoked when a remote central device unsubscribes from a characteristic’s value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic;

// peripheralManagerIsReadyToUpdateSubscribers:
// Invoked when a local peripheral device is again ready to send characteristic value updates. (required)
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral;

// Receiving Read and Write Requests

// peripheralManager:didReceiveReadRequest:
// Invoked when a local peripheral device receives an Attribute Protocol (ATT) read request for a characteristic that has a dynamic value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request;

// peripheralManager:didReceiveWriteRequests:
// Invoked when a local peripheral device receives an Attribute Protocol (ATT) write request for a characteristic that has a dynamic value.
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests;


@end
