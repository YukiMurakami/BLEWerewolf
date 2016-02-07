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
-(void)didReceiveAdvertiseGameroomInfo:(NSDictionary*)gameroomInfo;
@end

@interface BWSendMessageManager : NSObject

@property (nonatomic) id<BWSendMessageManagerDelegate> delegate;
@property (nonatomic) BOOL isPeripheral;

+ (instancetype)sharedInstance;
+ (void)resetSharedInstance;
- (void)setIsPeripheralParams:(BOOL)isPeripheral;
- (BOOL)isPeripheral;

- (void)startAdvertiseGameRoomInfo:(NSString*)gameIdString;//ゲームIDの送信用 ペリフェラル→セントラル

- (void)sendMessageForPeripheral:(NSString*)message;//セントラル→ペリフェラル
- (void)sendMessageForAllCentrals:(NSString*)message;//ペリフェラル→全セントラル
- (void)sendMessageWithAddressId:(NSString*)message toId:(NSString*)toId;


- (void)setPeripheralId:(NSString *)peripheralId;
- (BOOL)addCentralIdsObject:(NSString*)centralId;
- (void)resetCentralIds;


@end
