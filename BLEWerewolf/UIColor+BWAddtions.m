//
//  UIColor+BWAddtions.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "UIColor+BWAddtions.h"

@implementation UIColor (BWAddtions)

+ (UIColor *)colorWithHex:(uint32_t)hex {
    
    uint16_t redHex = (hex >> 16) & 0xff;
    uint16_t greenHex = (hex >> 8) & 0xff;
    uint16_t blueHex = (hex >> 0) & 0xff;
    
    CGFloat red = (CGFloat)redHex / 255.0f;
    CGFloat green = (CGFloat)greenHex / 255.0f;
    CGFloat blue = (CGFloat)blueHex / 255.0f;
    
    return [self colorWithRed:red green:green blue:blue alpha:1.0f];
}

+ (UIColor *)werewolfBubbleColor {//赤
    return [self colorWithHex:0xff8585];
}
+ (UIColor *)werewolfPartnerBubbleColor {//薄い赤
    return [self colorWithHex:0xffbbbb];
}
+ (UIColor *)gmBubbleColor {//空色
    return [self colorWithHex:0x00ccff];
}
+ (UIColor *)villagerBubbleColor {//草色
    return [self colorWithHex:0xc4ff99];
}
+ (UIColor *)fortuneTellerBubbleColor {//黄色
    return [self colorWithHex:0xffff6a];
}

+ (UIColor *)getPlayerColor:(NSInteger)id {
    NSArray *colors = @[@(0xff0000),
                        @(0xffff00),
                        @(0x00ff00),
                        @(0x00ffff),
                        @(0x0000ff),
                        @(0xff00ff),
                        @(0x800000),
                        @(0x808000),
                        @(0x008000),
                        @(0x008080),
                        @(0x000080),
                        @(0x800080),
                        ];
    if(id < 0) return [self colorWithHex:0xffffff];
    NSInteger index = id % colors.count;
    return [self colorWithHex:[colors[index]integerValue]];
}

@end
