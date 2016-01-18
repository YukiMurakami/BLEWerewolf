//
//  BWWaitConnectionScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWCentralManager.h"
#import "BWPeripheralManager.h"

@interface BWWaitConnectionScene : SKScene <BWCentralManagerDelegate,BWPeripheralManagerDelegate>{
    SKSpriteNode *backgroundNode;
    BWCentralManager *centralManager;
    BWPeripheralManager *peripheralManager;
    
    NSString *printMessage;
    
}

-(void)settingSubServer:(NSMutableArray*)_playerInfo;

@end
