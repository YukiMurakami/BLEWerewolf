//
//  BWRuleCheckScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWRuleCheckScene.h"

@implementation BWRuleCheckScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    centralManager = [BWCentralManager sharedInstance];
    centralManager.delegate = self;
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    [self addChild:backgroundNode];
}

-(void)didReceivedMessage:(NSString *)message {
    
}

@end
