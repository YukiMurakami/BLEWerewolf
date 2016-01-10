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
    
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.8, self.size.width*0.8/4) title:@"ルール設定"];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - self.size.width*0.1);
    [background addChild:titleNode];
   
    
    
    NSString *afternoonTime = [NSString stringWithFormat:@"%d分",(int)[infoDic[@"timer"]integerValue]];
    NSString *nightTime = [NSString stringWithFormat:@"%d分",(int)[infoDic[@"nightTimer"]integerValue]];
    NSString *canGuardString = @"あり";
    if(![infoDic[@"canContinuousGuard"]boolValue]) {
        canGuardString = @"なし";
    }
    NSString *lackString = @"なし";
    if([infoDic[@"isLacking"]boolValue]) {
        lackString = @"あり";
    }
    NSString *fortuneString = [[BWUtility getFortuneButtonString:[infoDic[@"fortuneMode"]integerValue]] substringFromIndex:5];
    
    
    NSArray *buttonInfos = @[@{@"text":@"議論時間",@"name":@"timerButton",@"param":afternoonTime},
                             @{@"text":@"夜時間",@"name":@"nightTimerButton",@"param":nightTime},
                             @{@"text":@"初日占い",@"name":@"fortuneButton",@"param":fortuneString},
                             @{@"text":@"役かけ",@"name":@"lackingButton",@"param":lackString},
                             @{@"text":@"連続護衛",@"name":@"guardButton",@"param":canGuardString},
                             ];
    
    
    BWButtonNode *backButton = [[BWButtonNode alloc]init];
    [backButton makeButtonWithSize:CGSizeMake(self.size.width*0.3, self.size.width*0.8/5) name:@"back" title:@"戻る" boldRate:1.0];
    backButton.position = CGPointMake(-self.size.width/2+self.size.width*0.1+backButton.size.width/2, -self.size.height/2 + self.size.width*0.1 + backButton.size.height/2);
    backButton.delegate = self;
    [background addChild:backButton];
    
    BWButtonNode *defaultButton = [[BWButtonNode alloc]init];
    [defaultButton makeButtonWithSize:CGSizeMake(self.size.width-(self.size.width*0.1*3)-backButton.size.width, self.size.width*0.8/5) name:@"default" title:@"推奨設定" boldRate:1.0];
    defaultButton.position = CGPointMake(backButton.position.x+(backButton.size.width+defaultButton.size.width)/2+self.size.width*0.1, -self.size.height/2 + self.size.width*0.1 + backButton.size.height/2);
    defaultButton.delegate = self;
    [background addChild:defaultButton];
    
    
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.height*0.08);
    CGFloat margin = (self.size.height - self.size.width*0.1*2 - titleNode.size.height - backButton.size.height - buttonSize.height*buttonInfos.count)/(buttonInfos.count+1);
    buttons = [NSMutableArray array];
    for(NSInteger i=0;i<buttonInfos.count;i++) {
        NSDictionary *info = buttonInfos[i];
        BWRuleButtonNode *buttonNode = [[BWRuleButtonNode alloc]init];
        [buttonNode makeButtonWithSize:buttonSize name:info[@"name"] title:info[@"text"] param:info[@"param"] delegate:self];
        buttonNode.position = CGPointMake(0, -1*(buttonInfos.count/2.0 - i - 0.5)*(margin+buttonSize.height));
        [background addChild:buttonNode];
        [buttons addObject:buttonNode];
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
    
    
    
    
    
}

-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"back"]) {
        [(BWSettingScene *) toBackScene setRuleInfo:infoDic] ;
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
        [self.view presentScene:toBackScene transition:transition];
    }
    
    if([name isEqualToString:@"default"]) {
        [self setDefaultInfo];
    }
    if([name isEqualToString:@"timerButton"]) {
        NSInteger minute = [infoDic[@"timer"]integerValue];
        minute++;
        if(minute > 10) minute = 1;
        
        [infoDic setObject:@(minute) forKey:@"timer"];
        
        [self reloadButtonStrings];
    }
    
    if([name isEqualToString:@"nightTimerButton"]) {
        NSInteger minute = [infoDic[@"nightTimer"]integerValue];
        minute++;
        if(minute > 5) minute = 1;
        
        [infoDic setObject:@(minute) forKey:@"nightTimer"];
        
        [self reloadButtonStrings];
    }
    
    if([name isEqualToString:@"fortuneButton"]) {
        NSInteger mode = [infoDic[@"fortuneMode"]integerValue];
        mode++;
        if(mode > 2) mode = 0;
        [infoDic setObject:@(mode) forKeyedSubscript:@"fortuneMode"];
        [self reloadButtonStrings];
    }
    
    if([name isEqualToString:@"lackingButton"]) {
        BOOL isLack = [infoDic[@"isLacking"]boolValue];
        
        if(isLack) {
            isLack = NO;
        } else {
            isLack = YES;
        }
        
        [infoDic setObject:@(isLack) forKeyedSubscript:@"isLacking"];
        [self reloadButtonStrings];
    }
    
    if([name isEqualToString:@"guardButton"]) {
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
    [infoDic setObject:@1 forKey:@"timer"];
    [infoDic setObject:@1 forKey:@"nightTimer"];
    [infoDic setObject:@(FortuneTellerModeFree) forKeyedSubscript:@"fortuneMode"];
    [infoDic setObject:@NO forKeyedSubscript:@"isLacking"];
    [infoDic setObject:@YES forKeyedSubscript:@"canContinuousGuard"];
    
    [self reloadButtonStrings];
}

-(void)reloadButtonStrings {
    NSString *afternoonTime = [NSString stringWithFormat:@"%d分",(int)[infoDic[@"timer"]integerValue]];
    NSString *nightTime = [NSString stringWithFormat:@"%d分",(int)[infoDic[@"nightTimer"]integerValue]];
    NSString *canGuardString = @"あり";
    if(![infoDic[@"canContinuousGuard"]boolValue]) {
        canGuardString = @"なし";
    }
    NSString *lackString = @"なし";
    if([infoDic[@"isLacking"]boolValue]) {
        lackString = @"あり";
    }
    NSString *fortuneString = [[BWUtility getFortuneButtonString:[infoDic[@"fortuneMode"]integerValue]] substringFromIndex:5];
    
    
    NSArray *buttonInfos = @[@{@"text":@"議論時間",@"name":@"timerButton",@"param":afternoonTime},
                             @{@"text":@"夜時間",@"name":@"nightTimerButton",@"param":nightTime},
                             @{@"text":@"初日占い",@"name":@"fortuneButton",@"param":fortuneString},
                             @{@"text":@"役かけ",@"name":@"lackingButton",@"param":lackString},
                             @{@"text":@"連続護衛",@"name":@"guardButton",@"param":canGuardString},
                             ];
    
    for(NSInteger i=0;i<buttonInfos.count;i++) {
        NSDictionary *info = buttonInfos[i];
        BWRuleButtonNode *buttonNode = buttons[i];
        buttonNode.param.text = info[@"param"];
    }
}

@end
