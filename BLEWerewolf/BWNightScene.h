//
//  BWNightScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "BWPeripheralManager.h"
#import "BWCentralManager.h"
#import "BWMessageViewController.h"

@interface BWNightScene : SKScene <BWPeripheralManagerDelegate,BWCentralManagerDelegate,BWMessageViewControllerDelegate> {
    SKSpriteNode *backgroundNode;
    BWCentralManager *centralManager;
    BWPeripheralManager *peripheralManager;
    
    NSMutableDictionary *infoDic;
    
    BWMessageViewController *messageViewController;
    
    //この画面からはペリフェラル、セントラルで共通で作る
    //ただし、内部処理は区別して行う
    BOOL isPeripheral;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic;

@end
