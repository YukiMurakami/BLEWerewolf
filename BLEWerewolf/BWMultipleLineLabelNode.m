//
//  BWMultipleLineLabelNode.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/08/16.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWMultipleLineLabelNode.h"

@implementation BWMultipleLineLabelNode

-(void)setText :(NSString *)string fontSize:(CGFloat)fontSize fontColor:(UIColor*)fontColor {
    
    NSMutableArray *lines = [NSMutableArray array];
    
    NSString *buf = string;
    int index = 0;
    
    while(true) {
        
        NSString *buf2 = [buf substringToIndex:index];
        int L = (int)[buf2 lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
        double width = L * fontSize / 2;
        if(self.size.width < width) {
            NSString *buf3 = [buf substringToIndex:index];
            buf = [buf substringFromIndex:index];
            [lines addObject:buf3];
            // NSLog(@"%@",buf);
            index = -1;
        }
        index++;
        if(buf.length <= index) {
            NSString *buf3 = [buf substringToIndex:index];
            buf = [buf substringFromIndex:index];
            [lines addObject:buf3];
            //  NSLog(@"%@",buf);
            index = -1;
            break;
        }
    }
    
    for(int i=0;i<lines.count;i++) {
        SKLabelNode *node = [[SKLabelNode alloc]init];
        node.fontSize = fontSize;
        node.fontColor = [UIColor blackColor];
        node.fontName = @"HiraKakuProN-W3";
        node.text = lines[i];
        node.fontColor = fontColor;
        node.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        node.position = CGPointMake(-self.size.width/2-fontSize/3,self.size.height/2 - (self.size.height-lines.count*fontSize)/2-(i+1)*fontSize);
        [self addChild:node];
    }
}

@end
