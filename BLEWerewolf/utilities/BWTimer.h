//
//  BWTimer.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@protocol BWTimerDelegate
-(void)didDecreaseTime:(NSInteger)seconds;
@end

@interface BWTimer : SKSpriteNode {
    NSDate *start;
    NSDate *end;
    
    id<BWTimerDelegate> _delegate;
}
@property (nonatomic) id<BWTimerDelegate> delegate;

-(void)setSeconds:(NSInteger)second;
-(NSInteger)getSeconds;
-(void)initNodeWithFontColor:(UIColor*)color;
-(void)stopTimer;

@end
