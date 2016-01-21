//
//  BWTransferManager.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/21.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWTransferManager.h"
#import "TransferService.h"
#import "BWUtility.h"

@implementation BWTransferManager

static BWTransferManager *sharedInstance = nil;

#pragma mark - Singleton
+ (instancetype)sharedInstance
{
    @synchronized(self) {
        if(!sharedInstance) {
            sharedInstance = [[BWTransferManager alloc] initSharedInstance];
            
            sharedInstance.centralManager = [BWCentralManager sharedInstance];
            sharedInstance.centralManager.transferDelegate = sharedInstance;
            sharedInstance.peripheralManager = [BWPeripheralManager sharedInstance];
            sharedInstance.peripheralManager.transferDelegate = sharedInstance;
        }
    }
    
    return sharedInstance;
}


- (id)initSharedInstance {
    self = [super init];
    if (self) {
        // 初期化処理
        
    }
    return self;
}


+ (void)resetSharedInstance {
    sharedInstance.centralManager = nil;
    sharedInstance = nil;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)didReceiveTransferMessageCentral:(NSString *)message {
    //ペリフェラル→セントラルへの中継処理
    //「1:NNNNNN:T..T:C..C:P..P:message」の形式で送信する（NNNNNNはゲームID,T..TはシグナルID,C..Cは送り先ID）
    NSLog(@"中継 peripharal -> central");
    SignalKind kind = [[BWUtility getCommand:message]integerValue];
    if(kind == SignalKindNormal) {
        NSArray *array = [message componentsSeparatedByString:@":"];
        NSString *contentMessage = @"";
        for(NSInteger i=5;i<array.count;i++) {
            if(i == 5) {
                contentMessage = [NSString stringWithFormat:@"%@%@",contentMessage,array[i]];
            } else {
                contentMessage = [NSString stringWithFormat:@"%@:%@",contentMessage,array[i]];
            }
        }
        
        NSString *centralId = array[3];
        [self.peripheralManager sendNormalMessage:contentMessage toIdentificationId:centralId interval:5.0 timeOut:100.0 firstWait:0.0];
    }
}

- (void)didReceiveTransferMessagePeripheral:(NSString *)message {
    //セントラル→ペリフェラルへの中継処理
    NSLog(@"中継　central -> peripheral");
    SignalKind kind = [[BWUtility getCommand:message]integerValue];
    if(kind == SignalKindNormal) {
        //「1:NNNNNN:T..T:C..C:P..P:message」
        NSArray *array = [message componentsSeparatedByString:@":"];
        NSString *contentMessage = @"";
        for(NSInteger i=5;i<array.count;i++) {
            if(i == 5) {
                contentMessage = [NSString stringWithFormat:@"%@%@",contentMessage,array[i]];
            } else {
                contentMessage = [NSString stringWithFormat:@"%@:%@",contentMessage,array[i]];
            }
        }
        
        [self.centralManager sendNormalMessage:contentMessage interval:5.0 timeOut:100.0 firstWait:0.0];
    }
    
}


@end
