//
//  BWTransferManager.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/21.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BWCentralManager.h"
#import "BWPeripheralManager.h"

@interface BWTransferManager : NSObject <BWCentralTransferDelegate,BWPeripheralTransferDelegate>

@property (nonatomic,strong) BWCentralManager *centralManager;
@property (nonatomic,strong) BWPeripheralManager *peripheralManager;

+ (instancetype)sharedInstance;
+ (void)resetSharedInstance;
- (id)initSharedInstance;
- (id)init;

@end
