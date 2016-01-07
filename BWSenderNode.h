//
//  BWSenderNode.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/07.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "TransferService.h"

@interface BWSenderNode : SKSpriteNode {
    
}
@property (nonatomic) NSInteger signalId;
@property (nonatomic) SignalKind signalKind;
@property (nonatomic) NSDate *firstSendDate;
@property (nonatomic) CGFloat timeOutSeconds;
@property (nonatomic) NSString *message;
@property (nonatomic) BOOL isReceived;
@property (nonatomic) NSString *toIdentificationId;

@end
