//
//  LWRuleSettingScene.h
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/22.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "BWSettingScene.h"
#import "BWRuleButtonNode.h"
#import "BWButtonNode.h"

@interface LWRuleSettingScene : SKScene <BWRuleButtonNodeDelegate,BWButtonNodeDelegate> {
    SKScene *toBackScene;
    NSMutableDictionary *infoDic;
    NSMutableArray *buttons;
}

-(void) setBackScene :(SKScene *)backScene infoDic:(NSMutableDictionary *)_infoDic;

@end
