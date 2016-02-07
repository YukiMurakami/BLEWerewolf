//
//  BWNightScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "BWSendMessageManager.h"
#import "BWMessageViewController.h"
#import "BWTimer.h"

@interface BWNightScene : SKScene <BWSendMessageManagerDelegate,BWMessageViewControllerDelegate,BWTimerDelegate,UITableViewDataSource,UITableViewDelegate> {
    SKSpriteNode *backgroundNode;
    BWSendMessageManager *sendManager;
    
    NSMutableDictionary *infoDic;
    
    BWMessageViewController *messageViewController;
    
    BWTimer *timer;
    
    //この画面からはペリフェラル、セントラルで共通で作る
    //ただし、内部処理は区別して行う
    BOOL isPeripheral;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic;

@end
