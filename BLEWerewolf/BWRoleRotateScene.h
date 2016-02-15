//
//  BWRoleRotateScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWSocketManager.h"

@interface BWRoleRotateScene : SKScene <BWSocketManagerDelegate,UITableViewDataSource,UITableViewDelegate> {
    SKSpriteNode *backgroundNode;
    BWSocketManager *socketManager;
    
    NSMutableDictionary *infoDic;
    
    UITableView *table;
    NSMutableArray *tablePlayerArray;
    
    //この画面からはペリフェラル、セントラルで共通で作る
    //ただし、内部処理は区別して行う
    BOOL isPeripheral;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic;

@end
