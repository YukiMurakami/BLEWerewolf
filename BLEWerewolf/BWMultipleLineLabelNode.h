//
//  BWMultipleLineLabelNode.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/08/16.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface BWMultipleLineLabelNode : SKSpriteNode

-(void)setText :(NSString *)string fontSize:(CGFloat)fontSize fontColor:(UIColor*)fontColor;

-(NSString*)getAllText;

-(UIColor*)getFontColor;
-(CGFloat)getAllFontSize;

@end
