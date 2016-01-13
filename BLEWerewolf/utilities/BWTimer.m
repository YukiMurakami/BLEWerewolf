//
//  BWTimer.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWTimer.h"

@implementation BWTimer {
    NSInteger lastTimer;
    SKLabelNode *timeLabel;
    NSTimer *nstimer;
}
@synthesize delegate = _delegate;

-(void)initNodeWithFontColor:(UIColor*)color {
    self.texture = [SKTexture textureWithImageNamed:@"time_frame.png"];
    
    timeLabel = [[SKLabelNode alloc]init];
    timeLabel.fontName = @"HiraKakuProN-W6";
    timeLabel.fontSize = self.size.height*0.6;
    timeLabel.position = CGPointMake(0, -self.size.height*0.2);
    
    [self updateNode];
    [self addChild:timeLabel];
}

-(void)setSeconds:(NSInteger)second {
    start = [NSDate date];
    end = [NSDate dateWithTimeIntervalSinceNow:second];
    nstimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSeconds) userInfo:nil repeats:YES];
}

-(NSInteger)getSeconds {
    NSInteger seconds = (NSInteger)[end timeIntervalSinceNow];
    return seconds;
}

-(void)stopTimer {
    if ([nstimer isValid]) {
        [nstimer invalidate];
    }
}

-(void)updateSeconds {
    NSInteger seconds = (NSInteger)[end timeIntervalSinceNow];
    if(lastTimer > seconds) {
        [_delegate didDecreaseTime:seconds];
        if(seconds >= 0) [self updateNode];
    }
    lastTimer = seconds;
}

-(void)updateNode {
    NSInteger minute = [self getSeconds] / 60;
    NSInteger second = [self getSeconds] % 60;
    timeLabel.text = [NSString stringWithFormat:@"%02d:%02d",(int)minute,(int)second];
}

@end
