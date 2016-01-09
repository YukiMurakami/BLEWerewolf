//
//  ViewController.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/23.
//  Copyright (c) 2015年. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>

@interface BWViewController : UIViewController

@property (nonatomic) SKView *viewForSenderNodes;
@property (nonatomic) SKScene *sceneForSenderNodes;

-(void)addRecieveMessage:(NSString*)message;
-(void)addSendMessage:(NSString*)message;
-(void)addPlayersInfo:(NSMutableArray*)playersArray;
-(void)flipHiddenDebugView;
@end

