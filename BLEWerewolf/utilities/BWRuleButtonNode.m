//
//  BWRuleButtonNode.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/10.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWRuleButtonNode.h"

@implementation BWRuleButtonNode {
    SKSpriteNode *buttonNode;
}
@synthesize delegate = _delegate;

-(void)makeButtonWithSize:(CGSize)size name:(NSString*)name title:(NSString*)title param:(NSString*)param delegate:(id)delegateid {
    //1446,223
    self.size = size;
    buttonNode = [[SKSpriteNode alloc]initWithImageNamed:@"ui_tableItem_space.png"];
    buttonNode.size = size;
    
    self.title = [[SKLabelNode alloc]init];
    self.title.text = title;
    self.title.fontName = @"HiraKaku-ProW3";
    self.title.fontSize = size.height*0.5;
    self.title.position = CGPointMake(-self.size.width*0.1-(2.5-title.length/2.0)*self.title.fontSize, 0);
    self.title.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;

    self.param = [[SKLabelNode alloc]init];
    self.param.text = param;
    self.param.fontName = @"HiraKaku-ProW3";
    self.param.fontSize = size.height*0.5;
    self.param.position = CGPointMake(self.size.width*0.3, 0);
    self.param.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    
    self.userInteractionEnabled = YES;
    
    self.name = name;
    [self addChild:buttonNode];
    [self addChild:self.title];
    [self addChild:self.param];
    
    self.delegate = delegateid;
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    buttonNode.texture = [SKTexture textureWithImageNamed:@"ui_tableItem_space_push.png"];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    buttonNode.texture = [SKTexture textureWithImageNamed:@"ui_tableItem_space.png"];
    [_delegate buttonNode:self didPushedWithName:self.name];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    buttonNode.texture = [SKTexture textureWithImageNamed:@"ui_tableItem_space_push.png"];
}

@end

