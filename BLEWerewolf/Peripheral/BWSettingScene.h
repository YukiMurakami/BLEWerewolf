//
//  BWSettingScene.h
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "LWRoleSettingScene.h"
#import "LWRuleSettingScene.h"

#import "BWRuleCheckScene.h"
#import "BWButtonNode.h"

//#import "LWGameScene.h"
//#import "LWRoleTableScene.h"

@interface BWSettingScene : SKScene <BWButtonNodeDelegate> {
    NSInteger player;
    
    SKScene *rollSettingScene;
    SKScene *ruleSettingScene;
    
    NSMutableDictionary *informations;
    

}

-(void)sendPlayerInfo:(NSMutableArray*)playerArray;
-(void)setRollInfo :(NSMutableArray *)rollInfo ;
-(void)setRuleInfo :(NSMutableDictionary *)ruleInfo ;


@end
