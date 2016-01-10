//
//  BWButtonNode.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/10.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWButtonNode.h"
#import "BWAppDelegate.h"



@implementation BWButtonNode {
    SKSpriteNode *buttonNode;
}
@synthesize delegate = _delegate;

-(void)makeButtonWithSize:(CGSize)size name:(NSString*)name title:(NSString*)title boldRate:(CGFloat)_boldRate {
    BWAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    CGFloat viewWidth = appDelegate.window.rootViewController.view.frame.size.width;
    
    self.size = size;
    buttonNode = [[SKSpriteNode alloc]initWithImageNamed:@"ui_button.png"];
    CGFloat boldRate = viewWidth/375*_boldRate;
    buttonNode.size = CGSizeMake(64*boldRate,64*boldRate);
    buttonNode.xScale = size.width/64/boldRate;
    buttonNode.yScale = size.height/64/boldRate;
    NSLog(@"%f,%f",buttonNode.xScale,buttonNode.yScale);
    CGFloat margin = 0.49;
    buttonNode.centerRect = CGRectMake(margin, margin, 1.0-margin*2,1.0-margin*2);
    buttonNode.position = CGPointMake(0, 0);
    
    SKLabelNode *labelNode = [[SKLabelNode alloc]init];
    labelNode.text = title;
    labelNode.fontSize = self.size.height*0.4;
    labelNode.fontColor = [UIColor blackColor];
    labelNode.color = [UIColor grayColor];
    labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    
    self.userInteractionEnabled = YES;
   
    self.name = name;
    [self addChild:buttonNode];
    [self addChild:labelNode];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    buttonNode.texture = [SKTexture textureWithImageNamed:@"ui_buttonPush.png"];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    buttonNode.texture = [SKTexture textureWithImageNamed:@"ui_button.png"];
    [_delegate buttonNode:self didPushedWithName:self.name];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    buttonNode.texture = [SKTexture textureWithImageNamed:@"ui_buttonPush.png"];
}

@end
