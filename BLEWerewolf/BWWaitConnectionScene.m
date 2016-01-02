//
//  BWWaitConnectionScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWWaitConnectionScene.h"
#import "BWUtility.h"
#import "BWRuleCheckScene.h"

@implementation BWWaitConnectionScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    centralManager = [BWCentralManager sharedInstance];
    centralManager.delegate = self;
    
    printMessage = @"接続中、、、";
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"night.jpg"];
    [self addChild:backgroundNode];
    
    SKLabelNode *messageLabel = [[SKLabelNode alloc]init];
    messageLabel.fontColor = [UIColor whiteColor];
    messageLabel.fontSize = 50.0;
    messageLabel.text = printMessage;
    messageLabel.position = CGPointMake(0, 0);
    [backgroundNode addChild:messageLabel];
}

-(void)didReceivedMessage:(NSString *)message {
    //participateAllow:A..A
    if([[BWUtility getCommand:message] isEqualToString:@"participateAllow"]) {
        NSString *identificationString = [BWUtility getCommandContents:message][0];
        if([identificationString isEqualToString:[BWUtility getIdentificationString]]) {
            NSLog(@"接続完了");
            if([printMessage isEqualToString:@"接続中、、、"]) {
                printMessage = @"ルール設定待ち";
                [self initBackground];
            }
            /*
            BWRuleCheckScene *scene = [BWRuleCheckScene sceneWithSize:self.size];
            SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
            [self.view presentScene:scene transition:transition];
            */
        }
    }
}

@end
