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
    
    CGFloat margin = self.size.width*0.1;
    
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width-margin*2, (self.size.width-margin*2)/4) title:@"ゲーム設定"];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - margin);
    [background addChild:titleNode];
    
    SKSpriteNode *titleNode2 = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake((self.size.width-margin*2)*0.8, (self.size.width-margin*2)/4*0.8) title:[NSString stringWithFormat:@"プレイヤー：%d人",(int)[informations[@"players"] count] ]];
    titleNode2.position = CGPointMake(0, titleNode.position.y - titleNode.size.height/2 - titleNode2.size.height/2 - margin);
    [background addChild:titleNode2];
    
    NSInteger nButton = 3;
    for(int i=0;i<nButton;i++) {
        NSString *name;
        NSString *text;
        if(i==0) {name = @"role"; text = @"配役設定";}
        if(i==1) {name = @"rule"; text = @"ルール設定";}
        if(i==2) {name = @"start"; text = @"スタート";}
        
        CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.height*0.1);
        CGPoint buttonPosition = CGPointMake(0, -self.size.height*0.5+buttonSize.height/2+ margin+(buttonSize.height+margin) * (nButton-1-i));
        
        BWButtonNode *buttonNode = [[BWButtonNode alloc]init];
        [buttonNode makeButtonWithSize:buttonSize name:name title:text boldRate:1.0];
        buttonNode.position = buttonPosition;
        buttonNode.delegate = self;
        [background addChild:buttonNode];
    }
    
}

-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"role"]) {
        
        if(!rollSettingScene) {
            rollSettingScene = [LWRoleSettingScene sceneWithSize:self.size];
        }
        NSInteger playerCount = [informations[@"players"] count];
        NSMutableDictionary *info = [@{@"playerCount":@(playerCount),@"rollArray":informations[@"roles"]} mutableCopy];
        [(LWRoleSettingScene *) rollSettingScene setBackScene:self infoDic:info];
        
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.5];
        
        [self.view presentScene:rollSettingScene transition:transition];
        
    }
    
    
    if([name isEqualToString:@"rule"]) {
        
        if(!ruleSettingScene) {
            ruleSettingScene = [LWRuleSettingScene sceneWithSize:self.size];
        }
        
        NSMutableDictionary *info = informations[@"rules"];
        [(LWRuleSettingScene *) ruleSettingScene setBackScene:self infoDic:info];
        
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.5];
        
        [self.view presentScene:ruleSettingScene transition:transition];
        
    }
    
    
    if([name isEqualToString:@"start"]) {
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
        
        BWRuleCheckScene *scene = [BWRuleCheckScene sceneWithSize:self.size];
        [scene setCentralOrPeripheral:YES :informations];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    
}


-(void)setRollInfo :(NSMutableArray *)rollInfo {
    informations[@"rolls"] = rollInfo;
}

-(void)setRuleInfo :(NSMutableDictionary *)ruleInfo {
    informations[@"rules"] = ruleInfo;
}

@end
