//
//  BWUserSettingScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/01.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWTopScene.h"
#import "BWUserSettingScene.h"
#import "BWUtility.h"

@implementation BWUserSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    [self addChild:backgroundNode];
    
    
    
    SKSpriteNode *buttonNode = [BWUtility makeButton:@"戻る" size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"back" position:CGPointMake(0, -self.size.height/2 + self.size.width*0.7*0.2*2)];
    [backgroundNode addChild:buttonNode];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"back"]) {
        BWTopScene *scene = [BWTopScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
    
}

@end
