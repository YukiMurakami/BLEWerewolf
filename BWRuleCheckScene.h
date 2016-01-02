//
//  BWRuleCheckScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWCentralManager.h"

@interface BWRuleCheckScene : SKScene <BWCentralManagerDelegate> {
    SKSpriteNode *backgroundNode;
    BWCentralManager *centralManager;
}

@end
