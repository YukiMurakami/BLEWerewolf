//
//  BWGameSettingScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWSocketManager.h"

#import "BWGorgeousTableView.h"
#import "BWButtonNode.h"

@interface BWGameSettingScene : SKScene <UITableViewDelegate,UITableViewDataSource,BWButtonNodeDelegate,BWSocketManagerDelegate>

-(id)initWithSize:(CGSize)size gameId:(NSInteger)_gameId ;


@end
