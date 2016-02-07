//
//  BWSendMessageManager.h
//  NearByMessageChat
//
//  Created by Yuki Murakami on 2016/02/07.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BWSendMessageManagerDelegate
-(void)didReceiveMessage:(NSString*)message senderId:(NSString*)senderId;
-(void)didReceiveAdvertiseDevice:(NSString*)deviceId;
@end

@interface BWSendMessageManager : NSObject

@property (nonatomic) id<BWSendMessageManagerDelegate> delegate;

+ (instancetype)sharedInstance;
+ (void)resetSharedInstance;
- (void)setIsPeripheral:(BOOL)isPeripheral;
- (void)sendMyIdentificationId;

- (void)sendMessageForPeripheral:(NSString*)message;//セントラル→ペリフェラル
- (void)sendMessageForAllCentrals:(NSString*)message;//ペリフェラル→全セントラル
- (void)sendMessageWithAddressId:(NSString*)message toId:(NSString*)toId;


- (void)setPeripheralId:(NSString *)peripheralId;
- (BOOL)addCentralIdsObject:(NSString*)centralId;


@end
