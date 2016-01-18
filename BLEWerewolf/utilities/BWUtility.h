//
//  BWUtility.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(NSUInteger, FortuneTellerMode)
{
    FortuneTellerModeNone,
    FortuneTellerModeFree,
    FortuneTellerModeRevelation,
};

typedef NS_ENUM(NSUInteger, Role) {
    RoleVillager,
    RoleWerewolf,
    RoleFortuneTeller,
    RoleShaman,
    RoleMadman,
    RoleBodyguard,
    RoleJointOwner,
    RoleFox,
    //TODO::役職追加時変更点
};

typedef NS_ENUM(NSInteger,Winner) {
    WinnerVillager,
    WinnerWerewolf,
    WinnerFox,
    WinnerNone,//ゲーム続行
};

typedef NS_ENUM(NSInteger,ServerMode) {
    ServerModeNone,
    ServerModePeripheral,
    ServerModeCentral,
    ServerModeSubPeripheral,
};

@interface BWUtility : NSObject

+(SKSpriteNode *) makeButton :(NSString*) text
                         size:(CGSize)size
                         name:(NSString*)name
                     position:(CGPoint)position;

+ (NSInteger)getRandInteger :(NSInteger)maxInteger;

+ (NSString*)getRandomString :(NSInteger)digit;
+(NSMutableArray*) getRandomArray :(NSMutableArray*)array;

#pragma mark - role
+(NSMutableArray *) getDefaultRoleArray :(int) count ;
+(int) getMaxRoleCount ;
+(NSMutableDictionary *) getCardInfofromId :(int) cardId ;
+(SKTexture *) getCardTexture :(int) cardId;
+ (NSString*)getFortuneButtonString :(FortuneTellerMode)mode;
+(NSString*)getRoleSetString:(NSMutableArray*)roles;
+(NSInteger)getMyPlayerId:(NSMutableDictionary*)infoDic;
+(NSInteger)getPlayerId:(NSMutableDictionary*)infoDic id:(NSString*)identificationId;
+(Role)getMyRoleId:(NSMutableDictionary*)infoDic;

#pragma mark - ui
+(SKSpriteNode*)makeFrameNodeWithBoldrate:(CGFloat)_boldRate size:(CGSize)size;
+(SKSpriteNode*)makeTitleNodeWithBoldrate:(CGFloat)boldRate size:(CGSize)size title:(NSString*)title;
+(SKSpriteNode*)makeMessageNodeWithBoldrate:(CGFloat)boldRate size:(CGSize)size text:(NSString*)text fontSize:(CGFloat)fontSize;


+(SKSpriteNode*)makeVoteResultNode:(CGSize)size position:(CGPoint)position texture:(SKTexture*)texture day:(NSInteger)day voteCount:(NSInteger)voteCount excutionerId:(NSInteger)excutionerId voteArray:(NSMutableArray*)voteArray infoDic:(NSMutableDictionary*)infoDic;
+(SKSpriteNode *) makeFrameNode :(CGSize)size position:(CGPoint)position color:(UIColor*)color texture:(SKTexture *)texture;
+(SKSpriteNode *) makeMessageNode :(CGSize)frameSize position:(CGPoint)position backColor:(UIColor*)color string:(NSString*)string fontSize:(CGFloat)fontSize fontColor:(UIColor*)fontColor;
+(SKSpriteNode *) makeMessageAndImageNode :(CGSize)messageSize position:(CGPoint)messagePosition color:(UIColor*)backColor string:(NSString*)message fontSize:(CGFloat)fontSize fontColor:(UIColor*)fontColor imageTexture:(SKTexture*)texture imageWidthRate:(CGFloat)imageWidthRate isRotateRight:(BOOL)isRotateRight;

#pragma mark - data
//固有識別文字列を取得（初回呼び出し時に生成し、userdefaultsに保存しておく）
+ (NSString*)getIdentificationString;
//ユーザデータを設定していたかどうか
+ (BOOL)wasSetting;
+ (NSString*)getUserName;

+ (void)setServerMode:(ServerMode)mode;
+ (ServerMode)getServerMode ;
+ (BOOL)isPeripheral;
+ (BOOL)isCentral;
+ (BOOL)isSubPeripheral;

+ (void)setPeripheralIdentificationId:(NSString*)identificationId;
+ (NSString*)getPeripheralIdentificationId;
+ (void)setCentralIdentifications:(NSMutableArray*)ids;
+ (NSMutableArray*)getCentralIdentifications;

#pragma mark - string
+(NSString*)getCommand :(NSString*)command;
+(NSArray*)getCommandContents:(NSString*)command;

@end
