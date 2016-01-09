//
//  ViewController.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/23.
//  Copyright (c) 2015年 yuki. All rights reserved.
//


#import "BWViewController.h"
#import "BWTopScene.h"

#import "BWMultipleLineLabelNode.h"


@implementation BWViewController {
    NSMutableArray *messages;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    //skView.showsFPS = NO;
    //skView.showsNodeCount = NO;
    
    self.viewForSenderNodes = [[SKView alloc]initWithFrame:CGRectMake(0,0, skView.bounds.size.width, skView.bounds.size.height)];
    
    [self.view addSubview:self.viewForSenderNodes];
    self.viewForSenderNodes.alpha = 0.75;
    self.viewForSenderNodes.userInteractionEnabled = NO;
    self.sceneForSenderNodes = [SKScene sceneWithSize:self.viewForSenderNodes.bounds.size];
    [self.viewForSenderNodes presentScene:self.sceneForSenderNodes];
    
    // Create and configure the scene.
    SKScene * scene = [BWTopScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    
    // Present the scene.
    [skView presentScene:scene];
    
    messages = [NSMutableArray array];
    NSInteger messageSize = 15;
    for(NSInteger i=0;i<messageSize;i++) {
        BWMultipleLineLabelNode *node = [[BWMultipleLineLabelNode alloc]init];
        node.size = CGSizeMake(self.viewForSenderNodes.bounds.size.width*0.9, self.viewForSenderNodes.bounds.size.height/messageSize);
        [node setText:@"" fontSize:self.viewForSenderNodes.bounds.size.height/messageSize*0.3 fontColor:[UIColor redColor]];
        node.position = CGPointMake(self.sceneForSenderNodes.size.width/2,self.sceneForSenderNodes.size.height/2 + (messageSize/2.0-0.5-i)*node.size.height);
        [self.sceneForSenderNodes addChild:node];
        [messages addObject:node];
    }
}

-(void)addRecieveMessage:(NSString*)message {
    CGFloat fontSize = 0.0;
    [self.view bringSubviewToFront:self.viewForSenderNodes];
    for(NSInteger i=0;i<messages.count-1;i++) {
        BWMultipleLineLabelNode *node1 = messages[i];
        BWMultipleLineLabelNode *node2 = messages[i+1];
        NSString *text = [node2 getAllText];
        UIColor *fontColor = [node2 getFontColor];
        fontSize = [node2 getAllFontSize];
        [node1 setText:text fontSize:fontSize fontColor:fontColor];
    }
    BWMultipleLineLabelNode *node = messages[messages.count-1];
    [node setText:message fontSize:fontSize fontColor:[UIColor redColor]];
}
-(void)addSendMessage:(NSString*)message {
    CGFloat fontSize = 0.0;
    [self.view bringSubviewToFront:self.viewForSenderNodes];
    for(NSInteger i=0;i<messages.count-1;i++) {
        BWMultipleLineLabelNode *node1 = messages[i];
        BWMultipleLineLabelNode *node2 = messages[i+1];
        NSString *text = [node2 getAllText];
        UIColor *fontColor = [node2 getFontColor];
        fontSize = [node2 getAllFontSize];
        [node1 setText:text fontSize:fontSize fontColor:fontColor];
    }
    BWMultipleLineLabelNode *node = messages[messages.count-1];
    [node setText:message fontSize:fontSize fontColor:[UIColor cyanColor]];
}

-(void)addPlayersInfo:(NSMutableArray*)playersArray {
    [self.view bringSubviewToFront:self.viewForSenderNodes];
    for(NSInteger i=0;i<playersArray.count;i++) {
        NSInteger isLive = [playersArray[i][@"isLive"]boolValue];
        NSString *name = playersArray[i][@"name"];
        NSString *id = playersArray[i][@"identificationId"];
        NSInteger roleId = [playersArray[i][@"roleId"]integerValue];
        NSString *mes = [NSString stringWithFormat:@"live:%d,roleId:%d,name:%@,id:%@",isLive,roleId,name,id];
        BWMultipleLineLabelNode *node = messages[i];

        [node setText:mes fontSize:12.0 fontColor:[UIColor greenColor]];
    }
}

-(void)flipHiddenDebugView {
    if(self.viewForSenderNodes.isHidden) {
        self.viewForSenderNodes.hidden = NO;
    } else {
        self.viewForSenderNodes.hidden = YES;
    }
}

@end