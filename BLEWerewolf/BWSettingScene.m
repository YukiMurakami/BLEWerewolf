//
//  BWSettingScene.m
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import "BWSettingScene.h"
#import "BWUtility.h"

@interface BWSettingScene () {
    SKLabelNode *playCount;
    
}

@end

@implementation BWSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    manager = [BWPeripheralManager sharedInstance];
    
    manager.delegate = self;
    
    return self;
}

-(void)willMoveFromView:(SKView *)view {
   
}

-(void)didMoveToView:(SKView *)view {
    [self initBackground];
}

-(void)sendPlayerInfo:(NSMutableArray*)playerArray {
    informations = [NSMutableDictionary dictionary];
    informations[@"players"] = playerArray;
    informations[@"rules"] = [@{}mutableCopy];
    informations[@"roles"] = [BWUtility getDefaultRoleArray:playerArray.count];
    player = playerArray.count;
}

-(void)initBackground {
    
    SKSpriteNode *background = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    background.size = self.size;
    background.position = CGPointMake(self.size.width/2,self.size.height/2);
    [self addChild:background];
    
    NSInteger nButton = 4;
    for(int i=0;i<nButton;i++) {
        NSString *name;
        NSString *text;
        if(i==0) {name = @"explain"; text = @"役職一覧";}
        if(i==1) {name = @"role"; text = @"配役設定";}
        if(i==2) {name = @"rule"; text = @"ルール設定";}
        if(i==3) {name = @"start"; text = @"スタート";}
        
        CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.height*0.1);
        CGPoint buttonPosition = CGPointMake(0, -self.size.height*0.5+buttonSize.height+buttonSize.height * 1.2 * (nButton-1-i));
        
        SKSpriteNode *playerButton = [BWUtility makeButton:text size:buttonSize name:name position:buttonPosition];
        [background addChild:playerButton];
    }
    
    
    playCount = [[SKLabelNode alloc]init];
    playCount.text = [NSString stringWithFormat:@"プレイヤー数：%d人",(int)[informations[@"players"] count] ];
    playCount.fontName = @"HiraKakuProN-W6";
    playCount.position = CGPointMake(0,self.size.height/2-70);
    [background addChild:playCount];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    
    if([node.name isEqualToString:@"explain"]) {
        /*
        LWRoleTableScene *scene = [LWRoleTableScene sceneWithSize:self.size];
        
        
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.5];
        [scene setBackScene:self];
        [self.view presentScene:scene transition:transition];
         */
    }
    
    if([node.name isEqualToString:@"role"]) {
        
        if(!rollSettingScene) {
            rollSettingScene = [LWRoleSettingScene sceneWithSize:self.size];
        }
        NSInteger playerCount = [informations[@"players"] count];
        NSMutableDictionary *info = [@{@"playerCount":@(playerCount),@"rollArray":informations[@"roles"]} mutableCopy];
        [(LWRoleSettingScene *) rollSettingScene setBackScene:self infoDic:info];
        
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.5];
        
        [self.view presentScene:rollSettingScene transition:transition];
        
    }
    
    
    if([node.name isEqualToString:@"rule"]) {
        
        if(!ruleSettingScene) {
            ruleSettingScene = [LWRuleSettingScene sceneWithSize:self.size];
        }
       
        NSMutableDictionary *info = informations[@"rules"];
        [(LWRuleSettingScene *) ruleSettingScene setBackScene:self infoDic:info];
        
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.5];
        
        [self.view presentScene:ruleSettingScene transition:transition];
         
    }
    
    
    if([node.name isEqualToString:@"start"]) {
        NSArray *role = informations[@"roles"];
        int sum = 0;
        for(int i=0;i<role.count;i++) {
            sum += [role[i]intValue];
        }
        if(sum != [informations[@"players"]count]) {
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"確認" message:[NSString stringWithFormat:@"プレイヤー数と配役数があってません。"]
                                      delegate:self cancelButtonTitle:nil otherButtonTitles:@"はい", nil];
            [alert show];
            return;
        }
        /*
        if(([roll[RollFortuneTeller]integerValue] <= 0 || [roll[RollWerewolf]integerValue]+[roll[RollBossWerewolf]integerValue] <= 0 || [roll[RollShaman]integerValue] <= 0 || [roll[RollBodyguard]integerValue] <= 0) && [roll[RollDetective]integerValue] >= 1) {
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"確認" message:[NSString stringWithFormat:@"名探偵を入れる場合は「占い師」「霊媒師」「ボディーガード」「人狼（大狼）」を各一人以上入れる必要があります。"]
                                      delegate:self cancelButtonTitle:nil otherButtonTitles:@"はい", nil];
            [alert show];
            return;
        }
         */
        
        
        BWRuleCheckScene *scene = [BWRuleCheckScene sceneWithSize:self.size];
        [scene setCentralOrPeripheral:YES :informations];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
}


-(void)setRollInfo :(NSMutableArray *)rollInfo {
    informations[@"rolls"] = rollInfo;
}

-(void)setRuleInfo :(NSMutableDictionary *)ruleInfo {
    informations[@"rules"] = ruleInfo;
}

@end
