//
//  BWMainScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/28.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "BWSocketManager.h"
#import "BWButtonNode.h"

@interface BWMainScene : SKScene <UITableViewDelegate,UITableViewDataSource,BWSocketManagerDelegate,BWButtonNodeDelegate>

@end
