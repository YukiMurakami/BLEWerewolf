//
//  LWRoleSettingScene.h
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "BWSettingScene.h"

@interface LWRoleSettingScene : SKScene <UITableViewDataSource,UITableViewDelegate> {
    UITableView *table;
    
    SKScene *toBackScene;
    
    NSMutableDictionary *infoDic;
    
    NSMutableArray *rollArray;
    
    
    
    int nPlayer;
    int selectedIndex;
}

-(void) setBackScene :(SKScene *)backScene infoDic:(NSMutableDictionary *)_infoDic ;
- (void)setCount :(NSInteger)row count:(NSInteger)count;
@end
