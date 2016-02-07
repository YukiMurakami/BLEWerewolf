//
//  BWWaitConnectionScene.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "BWSendMessageManager.h"

@interface BWWaitConnectionScene : SKScene <BWSendMessageManagerDelegate>{
    SKSpriteNode *backgroundNode;
    BWSendMessageManager *sendManager;
    
    NSString *printMessage;
}

-(void)setPrintMessage:(NSString*)mes;

@end
