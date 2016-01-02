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
        }
    }
    if([[BWUtility getCommand:message] isEqualToString:@"setting"]) {
        NSLog(@"ルール:%@",message);
        NSArray *components = [BWUtility getCommandContents:message];
        NSArray *roleStrings = [components[0] componentsSeparatedByString:@","];
        NSArray *ruleStrings = [components[1] componentsSeparatedByString:@","];
        NSMutableArray *roleArray = [NSMutableArray array];
        for(NSInteger i=0;i<roleStrings.count;i++) {
            [roleArray addObject:@([roleStrings[i]integerValue])];
        }
        
        NSMutableDictionary *ruleDic = [@{@"timer":@([ruleStrings[0]integerValue]),
                                          @"nightTimer":@([ruleStrings[1]integerValue]),
                                          @"fortuneMode":@([ruleStrings[2]integerValue]),
                                          @"canContinuousGuard":@([ruleStrings[3]integerValue]),
                                          @"isLacking":@([ruleStrings[4]integerValue])}mutableCopy];
        
        NSMutableDictionary *infoDic = [@{@"rules":ruleDic,@"roles":roleArray}mutableCopy];
        
        BWRuleCheckScene *scene = [BWRuleCheckScene sceneWithSize:self.size];
        [scene setCentralOrPeripheral:NO :infoDic];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
}

@end
