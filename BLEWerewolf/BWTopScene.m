//
//  BWTopScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/23.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWTopScene.h"
#import "BWMainScene.h"
#import "BWGameSettingScene.h"
#import "BWUtility.h"
#import "BWUserSettingScene.h"

#import "BWAppDelegate.h"
#import "BWViewController.h"



@implementation BWTopScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    self.backgroundColor = [UIColor redColor];
    
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    backgroundNode.size = CGSizeMake(self.size.width, self.size.height);
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:backgroundNode];
    
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.8, self.size.width*0.8/4) title:@"通信設定"];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - self.size.width*0.1);
    [backgroundNode addChild:titleNode];
    
    NSArray *buttons = @[@{@"title":@"サーバ",@"name":@"server"},
                         @{@"title":@"クライアント",@"name":@"client"},
                         @{@"title":@"ユーザ設定",@"name":@"setting"},
                         @{@"title":@"サブサーバ(9人以上)",@"name":@"subserver"}];
    
    CGSize buttonSize = CGSizeMake(self.size.width*0.8,self.size.width*0.8*0.2);
    if([BWUtility wasSetting]) {
        for(NSInteger i=0;i<buttons.count;i++) {
            BWButtonNode *buttonNode = [[BWButtonNode alloc]init];
            [buttonNode makeButtonWithSize:buttonSize name:buttons[i][@"name"] title:buttons[i][@"title"] boldRate:1.0];
            buttonNode.position = CGPointMake(0, buttonSize.width*0.3*(1-i));
            [backgroundNode addChild:buttonNode];
            buttonNode.delegate = self;
        }
    } else {
        NSInteger i=2;
        BWButtonNode *buttonNode = [[BWButtonNode alloc]init];
        [buttonNode makeButtonWithSize:buttonSize name:buttons[i][@"name"] title:buttons[i][@"title"] boldRate:1.0];
        buttonNode.position = CGPointMake(0, buttonSize.width*0.7*0.3*(1-i));
        [backgroundNode addChild:buttonNode];
        buttonNode.delegate = self;
    }
    
    for(NSInteger i=0;i<[BWUtility getMaxRoleCount];i++) {
        SKTexture *texture = [BWUtility getCardTexture:i];
        SKSpriteNode *node = [[SKSpriteNode alloc]initWithTexture:texture];
        [backgroundNode addChild:node];
        [node removeFromParent];
    }
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
 
    if(self.size.height-location.y < 50) {
        BWAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
        BWViewController *viewController = (BWViewController*)appDelegate.window.rootViewController;
        [viewController flipHiddenDebugView];
    }
}

-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"server"]) {
        BWGameSettingScene *scene = [BWGameSettingScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
        return;
    }
    if([name isEqualToString:@"client"]) {
        BWMainScene *scene = [BWMainScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
        return;
    }
    if([name isEqualToString:@"setting"]) {
        BWUserSettingScene *scene = [BWUserSettingScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
        return;
    }
}

@end
