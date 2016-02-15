//
//  BWWaitConnectionScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWSocketManager.h"

@interface BWWaitConnectionScene : SKScene <BWSocketManagerDelegate>{
    SKSpriteNode *backgroundNode;
    BWSocketManager *socketManager;
    
    NSString *printMessage;
}

-(void)setPrintMessage:(NSString*)mes;

@end
