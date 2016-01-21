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
#import "BWMainScene.h"

@implementation BWWaitConnectionScene {
    NSMutableArray *playerInfos;
    
    NSDate *timeoutDate;
    
    NSInteger timeoutCount;
    
    SKLabelNode *countLabel;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    centralManager = [BWCentralManager sharedInstance];
    centralManager.delegate = self;
    
    printMessage = @"接続中、、、";
    
    timeoutCount = 0;
    
    [self initBackground];
    
    return self;
}

-(void)didMoveToView:(SKView *)view {
    timeoutDate = [NSDate dateWithTimeIntervalSinceNow:30.0];
    
}

-(void)update:(NSTimeInterval)currentTime {
    if(![printMessage isEqualToString:@"接続中、、、"]) return;
    timeoutCount++;
    if(timeoutCount > 400) {
        timeoutCount=0;
        NSLog(@"aaaaaaa");
        NSDate *now = [NSDate date];
        NSComparisonResult result = [now compare:timeoutDate];
        if(result == NSOrderedDescending) {
            //Timeout
            
            //ゲーム部屋から退出通知（タイムアウトなど）「participateCancel:NNNNNN/C..C」
            [centralManager sendNormalMessage:[NSString stringWithFormat:@"participateCandel:%@/%@",[centralManager getGameId],[BWUtility getIdentificationString]] interval:5.0 timeOut:100.0 firstWait:0.0];
            
            BWMainScene *scene = [[BWMainScene alloc]initWithSize:self.size];
            SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
            [self.view presentScene:scene transition:transition];
        }
    }
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"night.jpg"];
    [self addChild:backgroundNode];
    
    SKLabelNode *messageLabel = [[SKLabelNode alloc]init];
    messageLabel.fontColor = [UIColor whiteColor];
    messageLabel.fontSize = 30.0;
    messageLabel.text = printMessage;
    messageLabel.position = CGPointMake(0, 0);
    [backgroundNode addChild:messageLabel];
    
    countLabel = [[SKLabelNode alloc]init];
    countLabel.fontColor = [UIColor whiteColor];
    countLabel.fontSize = 30.0;
    countLabel.text = @"0/0";
    countLabel.fontName = @"HiraKakuProN-W3";
    countLabel.position = CGPointMake(0, messageLabel.position.y - countLabel.fontSize*1.2);
    countLabel.hidden = YES;
    [backgroundNode addChild:countLabel];
}

-(void)setPrintMessage:(NSString*)mes {
    printMessage = mes;
    [self initBackground];
}

-(void)didReceivedMessage:(NSString *)message {
    //participateAllow:A..A
    if([printMessage isEqualToString:@"接続中、、、"] && [[BWUtility getCommand:message] isEqualToString:@"participateAllow"]) {
        NSString *identificationString = [BWUtility getCommandContents:message][0];
        if([identificationString isEqualToString:[BWUtility getIdentificationString]]) {
            NSLog(@"接続完了");
            if([printMessage isEqualToString:@"接続中、、、"]) {
                printMessage = @"プレイヤー情報受信中";
                [self initBackground];
            }
            
            
        }
    }
    //setting:/6,3,1,1,1,1/7,3,0,1,1
    if([printMessage isEqualToString:@"ルール設定待ち"] && [[BWUtility getCommand:message] isEqualToString:@"setting"]) {
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
        
        NSMutableDictionary *infoDic = [@{@"rules":ruleDic,@"roles":roleArray,@"players":playerInfos}mutableCopy];
        
        BWRuleCheckScene *scene = [BWRuleCheckScene sceneWithSize:self.size];
        [scene setCentralOrPeripheral:NO :infoDic];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
    
    //member:0/A..A/S..S/12
    if([printMessage isEqualToString:@"プレイヤー情報受信中"] && [[BWUtility getCommand:message] isEqualToString:@"member"]) {
        NSArray *contents = [BWUtility getCommandContents:message];
        NSInteger nPlayer = [contents[3]integerValue];
        NSInteger playerId = [contents[0]integerValue];
        NSString *nameString = contents[2];
        NSString *identificationid = contents[1];
        
        if(!playerInfos) {
            playerInfos = [NSMutableArray array];
            for(NSInteger i=0;i<nPlayer;i++) {
                [playerInfos addObject:[@{@"identificationId":@"",@"name":@""}mutableCopy]];
            }
        }
        
        playerInfos[playerId][@"identificationId"] = identificationid;
        playerInfos[playerId][@"name"] = nameString;
        
        NSInteger receivedCount = 0;
        for(NSInteger i=0;i<playerInfos.count;i++) {
            if(![playerInfos[i][@"identificationId"] isEqualToString:@""]) receivedCount++;
        }
        countLabel.text = [NSString stringWithFormat:@"%d/%d",receivedCount,playerInfos.count];
        countLabel.hidden = NO;
        
        BOOL isAllReceived = YES;
        for(NSInteger i=0;i<playerInfos.count;i++) {
            if([playerInfos[i][@"identificationId"] isEqualToString:@""]) {
                isAllReceived = NO;
                break;
            }
        }
        if(isAllReceived) {
            printMessage = @"ルール設定待ち";
            //・参加者情報受信完了通知「memberCheck:C..C」
            [centralManager sendNormalMessage:[NSString stringWithFormat:@"memberCheck:%@",[BWUtility getIdentificationString]] interval:5.0 timeOut:100.0 firstWait:0.0];
            [self initBackground];
        }
    }
    
    
}

@end
