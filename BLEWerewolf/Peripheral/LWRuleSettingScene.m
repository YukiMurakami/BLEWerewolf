//
//  LWRuleSettingScene.m
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/22.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import "LWRuleSettingScene.h"
#import "BWUtility.h"

@implementation LWRuleSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    return self;
}

-(void)initBackground {
    
    SKSpriteNode *background = [[SKSpriteNode alloc]initWithImageNamed:@"night.jpg"];
    background.size = self.size;
    background.position = CGPointMake(self.size.width/2,self.size.height/2);
    [self addChild:background];
    
   
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    CGFloat margin = buttonSize.height*0.25;
    
    NSString *lackString = @"役欠け：なし";
    if([infoDic[@"isLacking"]boolValue]) {
        lackString = @"役欠け：あり";
    }
    
    NSString *canGuardString = @"連続ガード：あり";
    if(![infoDic[@"canContinuousGuard"]boolValue]) {
        canGuardString = @"連続ガード：なし";
    }
    
    NSArray *buttonInfos = @[@{@"text":@"戻る",@"name":@"back"},
                             @{@"text":@"推奨設定",@"name":@"default"},
                             @{@"text":[NSString stringWithFormat:@"議論時間：%@分",infoDic[@"timer"]],@"name":@"timerButton"},
                             @{@"text":[NSString stringWithFormat:@"夜時間：%@分",infoDic[@"nightTimer"]],@"name":@"nightTimerButton"},
                             @{@"text":[BWUtility getFortuneButtonString:[infoDic[@"fortuneMode"]integerValue]],@"name":@"fortuneButton"},
                             @{@"text":lackString,@"name":@"lackingButton"},
                             @{@"text":canGuardString,@"name":@"guardButton"},
                             ];
    
    for(NSInteger i=0;i<buttonInfos.count;i++) {
        NSDictionary *info = buttonInfos[i];
        SKSpriteNode *button = [BWUtility makeButton:info[@"text"] size:buttonSize name:info[@"name"] position:CGPointMake(0, -1*(buttonInfos.count/2.0 - i - 0.5)*(margin+buttonSize.height))];
        [background addChild:button];
    }
    
    if([infoDic objectForKey:@"timer"] == nil) {
        [self setDefaultInfo];
    }
}

-(void) setBackScene :(SKScene *)backScene infoDic:(NSMutableDictionary *)_infoDic{
    toBackScene = (BWSettingScene *)backScene;
    infoDic = _infoDic;
    
    [self initBackground];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    
    if([node.name isEqualToString:@"back"]) {
        [(BWSettingScene *) toBackScene setRuleInfo:infoDic] ;
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
        [self.view presentScene:toBackScene transition:transition];
    }
    
    if([node.name isEqualToString:@"default"]) {
        [self setDefaultInfo];
    }
    
    if([node.name isEqualToString:@"timerButton"]) {
        NSInteger minute = [infoDic[@"timer"]integerValue];
        minute++;
        if(minute > 10) minute = 1;
        
        [infoDic setObject:@(minute) forKey:@"timer"];
        
        [self reloadButtonStrings];
    }
    
    if([node.name isEqualToString:@"nightTimerButton"]) {
        NSInteger minute = [infoDic[@"nightTimer"]integerValue];
        minute++;
        if(minute > 5) minute = 1;
        
        [infoDic setObject:@(minute) forKey:@"nightTimer"];
        
        [self reloadButtonStrings];
    }
    
    if([node.name isEqualToString:@"fortuneButton"]) {
        NSInteger mode = [infoDic[@"fortuneMode"]integerValue];
        mode++;
        if(mode > 2) mode = 0;
        [infoDic setObject:@(mode) forKeyedSubscript:@"fortuneMode"];
        [self reloadButtonStrings];
    }
    
    if([node.name isEqualToString:@"lackingButton"]) {
        BOOL isLack = [infoDic[@"isLacking"]boolValue];
        
        if(isLack) {
            isLack = NO;
        } else {
            isLack = YES;
        }
        
        [infoDic setObject:@(isLack) forKeyedSubscript:@"isLacking"];
        [self reloadButtonStrings];
    }
    
    if([node.name isEqualToString:@"guardButton"]) {
        BOOL canGuard = [infoDic[@"canContinuousGuard"]boolValue];
        
        if(canGuard) {
            canGuard = NO;
        } else {
            canGuard = YES;
        }
        
        [infoDic setObject:@(canGuard) forKeyedSubscript:@"canContinuousGuard"];
        [self reloadButtonStrings];
    }
}

-(void)setDefaultInfo {
    [infoDic setObject:@5 forKey:@"timer"];
    [infoDic setObject:@3 forKey:@"nightTimer"];
    [infoDic setObject:@(FortuneTellerModeFree) forKeyedSubscript:@"fortuneMode"];
    [infoDic setObject:@NO forKeyedSubscript:@"isLacking"];
    [infoDic setObject:@YES forKeyedSubscript:@"canContinuousGuard"];
    
    [self reloadButtonStrings];
}

-(void)reloadButtonStrings {
    [self.children[0] removeFromParent];
    [self initBackground];
    
}

@end
