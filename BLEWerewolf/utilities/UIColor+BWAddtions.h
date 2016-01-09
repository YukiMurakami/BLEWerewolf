//
//  UIColor+BWAddtions.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (BWAddtions)

//ex. [UIColor colorWithHex:0xeeeeee];
+ (UIColor *)colorWithHex:(uint32_t)hex;


+ (UIColor *)werewolfBubbleColor;
+ (UIColor *)werewolfPartnerBubbleColor;
+ (UIColor *)gmBubbleColor;
+ (UIColor *)villagerBubbleColor;
+ (UIColor *)fortuneTellerBubbleColor;
+ (UIColor *)shamanBubbleColor;

+ (UIColor *)getPlayerColor:(NSInteger)id;//gm は-1
@end
