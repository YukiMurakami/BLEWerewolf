//
//  BWUtility.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(NSUInteger, Roll) {
    RollVillager,
    RollWerewolf,
    RollFortuneTeller,
    RollShaman,
    RollMadman,
    RollBodyguard,
    RollJointOwner,
    RollFox,
    //TODO::役職追加時変更点
};

@interface BWUtility : NSObject

+(SKSpriteNode *) makeButton :(NSString*) text
                         size:(CGSize)size
                         name:(NSString*)name
                     position:(CGPoint)position;

+ (NSInteger)getRandInteger :(NSInteger)maxInteger;

+ (NSString*)getRandomString :(NSInteger)digit;

#pragma mark - data
//固有識別文字列を取得（初回呼び出し時に生成し、userdefaultsに保存しておく）
+ (NSString*)getIdentificationString;
//ユーザデータを設定していたかどうか
+ (BOOL)wasSetting;
+ (NSString*)getUserName;

@end
