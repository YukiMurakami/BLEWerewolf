//
//  BWRuleCheckScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWSendMessageManager.h"
#import "BWButtonNode.h"

@interface BWRuleCheckScene : SKScene <BWSendMessageManagerDelegate,UITableViewDataSource,UITableViewDelegate,BWButtonNodeDelegate> {
    SKSpriteNode *backgroundNode;
    BWSendMessageManager *sendManager;
    
    NSMutableDictionary *infoDic;
    
    
    
    //この画面からはペリフェラル、セントラルで共通で作る
    //ただし、内部処理は区別して行う
    BOOL isPeripheral;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic;

@end
