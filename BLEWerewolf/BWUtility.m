//
//  BWUtility.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWUtility.h"


@implementation BWUtility

+(SKSpriteNode *) makeButton :(NSString*) text
                         size:(CGSize)size
                         name:(NSString*)name
                     position:(CGPoint)position
{
    SKSpriteNode *button = [[SKSpriteNode alloc]initWithImageNamed:@"button.png"];
    button.size = size;
    button.position = position;
    button.name = name;
    SKLabelNode *buttonLabel = [[SKLabelNode alloc]init];
    buttonLabel.text = text;
    buttonLabel.fontSize = button.size.height*0.5;
    buttonLabel.fontName = @"HiraKakuProN-W3";
    buttonLabel.fontColor = [UIColor blackColor];
    buttonLabel.position = CGPointMake(0, -button.size.height*0.20);
    buttonLabel.name = name;
    [button addChild:buttonLabel];
    
    return button;
}

+ (NSInteger)getRandInteger :(NSInteger)maxInteger {
    return (NSInteger)arc4random_uniform((int)maxInteger);
}

+ (NSString*)getRandomString :(NSInteger)digit {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    uint8_t length = [letters length];
    char data[(int)digit];
    for (int x=0;x<digit;data[x++] = [letters characterAtIndex:arc4random_uniform(length)]);
    return [[NSString alloc] initWithBytes:data length:digit encoding:NSUTF8StringEncoding];
}

#pragma mark - data

//userdefault
//identificationString NSString : 端末別識別番号（初回起動時にUUIDと一切関係なくランダムに生成される）
//userData NSMutableDictionary : ユーザデータ情報

+ (NSString*)getIdentificationString {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *identificationString = [ud stringForKey:@"identificationString"];
    if(!identificationString) {
        identificationString = [BWUtility getRandomString:32];
        [ud setObject:identificationString forKey:@"identificationString"];
    }
    return identificationString;
}

+ (BOOL)wasSetting {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userData = [ud objectForKey:@"userData"];
    if(!userData) return NO;
    return YES;
}

+ (NSString*)getUserName {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userData = [ud objectForKey:@"userData"];
    if(!userData) return @"no_name";
    return userData[@"name"];
}


@end
