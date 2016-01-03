//
//  BWSettingScene.h
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWPeripheralManager.h"
#import "LWRoleSettingScene.h"
#import "LWRuleSettingScene.h"

#import "BWRuleCheckScene.h"

//#import "LWGameScene.h"
//#import "LWRoleTableScene.h"

@interface BWSettingScene : SKScene <BWPeripheralManagerDelegate> {
    NSInteger player;
    
    SKScene *rollSettingScene;
    SKScene *ruleSettingScene;
    SKScene *gameScene;
    
    NSMutableDictionary *informations;
    
    BWPeripheralManager *manager;
}

-(void)sendPlayerInfo:(NSMutableArray*)playerArray;
-(void)setRollInfo :(NSMutableArray *)rollInfo ;
-(void)setRuleInfo :(NSMutableDictionary *)ruleInfo ;

-(void)stopMessage ;
@end
