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
+ (UIColor *)gmBubbleColor {//白色
    return [self colorWithHex:0xffffff];
}
+ (UIColor *)villagerBubbleColor {//草色
    return [self colorWithHex:0xc4ff99];
}
+ (UIColor *)fortuneTellerBubbleColor {//紫色
    return [self colorWithHex:0xff6aff];
}
+ (UIColor *)shamanBubbleColor {//青色
    return [self colorWithHex:0x1111ff];
}
+ (UIColor *)bodyguardBubbleColor {//空色
    return [self colorWithHex:0x00ccff];
}
+ (UIColor*)madmanBubbleColor {//灰色
    return [self colorWithHex:0x888888];
}
+ (UIColor*)jointOwnerBubbleColor {//桃色
    return [self colorWithHex:0xff88ff];
}
+ (UIColor*)jointOwnerPartnerBubbleColor {//薄い桃色
    return [self colorWithHex:0xffbbff];
}

+ (UIColor *)getPlayerColor:(NSInteger)id {
    NSArray *colors = @[@(0xff1111),
                        @(0xffff11),
                        @(0x11ff11),
                        @(0x11ffff),
                        @(0x1111ff),
                        @(0xff11ff),
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
