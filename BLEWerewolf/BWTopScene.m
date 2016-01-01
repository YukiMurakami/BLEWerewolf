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
    
    NSArray *buttons = @[@{@"title":@"サーバ",@"name":@"server"},
                         @{@"title":@"クライアント",@"name":@"client"},
                         @{@"title":@"ユーザ設定",@"name":@"setting"}];
    
    if([BWUtility wasSetting]) {
        for(NSInteger i=0;i<3;i++) {
            SKSpriteNode *buttonNode = [BWUtility makeButton:buttons[i][@"title"] size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:buttons[i][@"name"] position:CGPointMake(0, self.size.width*0.7*0.2*(1-i))];
            [backgroundNode addChild:buttonNode];
        }
    } else {
        NSInteger i=2;
        SKSpriteNode *buttonNode = [BWUtility makeButton:buttons[i][@"title"] size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:buttons[i][@"name"] position:CGPointMake(0, 0)];
        [backgroundNode addChild:buttonNode];
    }
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"server"]) {
        BWGameSettingScene *scene = [BWGameSettingScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
    if([node.name isEqualToString:@"client"]) {
        BWMainScene *scene = [BWMainScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
    if([node.name isEqualToString:@"setting"]) {
        BWUserSettingScene *scene = [BWUserSettingScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
}

@end
