//
//  LWRuleSettingScene.h
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/22.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "BWSettingScene.h"

@interface LWRuleSettingScene : SKScene {
    SKScene *toBackScene;
    NSMutableDictionary *infoDic;
}

-(void) setBackScene :(SKScene *)backScene infoDic:(NSMutableDictionary *)_infoDic;

@end
