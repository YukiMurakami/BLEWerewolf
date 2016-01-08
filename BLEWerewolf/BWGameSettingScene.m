//
//  BWGameSettingScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWGameSettingScene.h"
#import "BWPeripheralManager.h"
#import "BWUtility.h"
#import "NSObject+BlocksWait.h"
#import "BWSettingScene.h"

@interface BWGameSettingScene () {
    BWPeripheralManager *manager;
    
    NSInteger gameId;
    
    UITableView *tableView;
    NSMutableArray *registeredPlayersArray;
    
    SKSpriteNode *buttonNode;
    
    NSInteger sendGlobalId;
    NSInteger memberAllCheckId;
}

@end

@implementation BWGameSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    gameId = [BWUtility getRandInteger:1000000];
    
    manager = [BWPeripheralManager sharedInstance];
    
    manager.delegate = self;
    
    
    registeredPlayersArray = [NSMutableArray array];
    
    //まずは自分を追加
    NSMutableDictionary *dic = [@{@"identificationId":[BWUtility getIdentificationString],@"name":[BWUtility getUserName]}mutableCopy];
    [registeredPlayersArray addObject:dic];
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    self.backgroundColor = [UIColor blueColor];
    
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    backgroundNode.size = CGSizeMake(self.size.width, self.size.height);
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:backgroundNode];
    
    
    SKLabelNode *title = [[SKLabelNode alloc]init];
    title.fontSize = self.size.height*0.05;
    title.text = [NSString stringWithFormat:@"プレイヤー登録画面"];
    SKLabelNode *title2 = [[SKLabelNode alloc]init];
    title2.fontSize = self.size.height*0.05;
    title2.text = [NSString stringWithFormat:@"ゲームID:%06ld（%ld人）",(long)gameId,registeredPlayersArray.count];
    title2.fontName = @"HiraKakuProN-W3";
    
    
    title.position = CGPointMake(0, self.size.height*0.4);
    title2.position = CGPointMake(0, self.size.height*0.3);
    [backgroundNode addChild:title];
    [backgroundNode addChild:title2];
    
    CGFloat margin = self.size.height * 0.05;
    
    buttonNode = [BWUtility makeButton:@"参加締め切り" size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"next" position:CGPointMake(0, -self.size.height/2+margin+self.size.width*0.2*0.7/2)];
    [backgroundNode addChild:buttonNode];
    
    if(!tableView) {
        tableView = [[UITableView alloc]initWithFrame:CGRectMake(margin, title.fontSize*2+margin*3, self.size.width-margin*2, self.size.height-margin*5-title.fontSize*2-buttonNode.size.height)];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = tableView.frame.size.height/6;
    }
    
    
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@",(long)gameId,[BWUtility getUserName]];
    sendGlobalId = [manager sendGlobalSignalMessage:message interval:3.0];
    
}


-(void)willMoveFromView:(SKView *)view {
    [tableView removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    
    [self.view addSubview:tableView];
    [tableView reloadData];
}

#pragma mark - tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return registeredPlayersArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    NSString *name = registeredPlayersArray[indexPath.row][@"name"];
    
    cell.textLabel.text = name;
    
    return cell;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"next"]) {
        [manager stopGlobalSignal:sendGlobalId];
        
        [buttonNode removeFromParent];
        
        NSMutableArray *messagesAndIdentificationIds = [NSMutableArray array];
        //member:0/A..A/S..S/12
        for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
            NSString *toIdentificationId = registeredPlayersArray[i][@"identificationId"];
            for(NSInteger j=0;j<registeredPlayersArray.count;j++) {
                NSString *identificationId = registeredPlayersArray[j][@"identificationId"];
                NSString *message = [NSString stringWithFormat:@"member:%d/%@/%@/%d",(int)j,identificationId,registeredPlayersArray[j][@"name"],(int)registeredPlayersArray.count];
                [messagesAndIdentificationIds addObject:@{@"message":message,@"identificationId":toIdentificationId}];
            }
        }
        memberAllCheckId = [manager sendNeedSynchronizeMessage:messagesAndIdentificationIds];
    }
}

#pragma mark - BWPeripheralManagerDelegate
-(void)didReceiveMessage:(NSString *)message {
    //participateRequest:NNNNNN/A..A(32)/S...S
    if([[BWUtility getCommand:message] isEqualToString:@"participateRequest"]) {
        NSArray *params = [BWUtility getCommandContents:message];
        NSString *identificationIdString = params[1];
        NSString *gameIdString = params[0];
        NSString *userNameString = params[2];
        
        //participateAllow:A..A
        [manager sendNormalMessage:[NSString stringWithFormat:@"participateAllow:%@",identificationIdString] toIdentificationId:identificationIdString interval:5.0 timeOut:15.0];
        
        if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]]) {
            
            BOOL isNew = YES;
            for(NSInteger i=0;i<registeredPlayersArray.count;i++) {
                if([registeredPlayersArray[i][@"identificationId"] isEqualToString:identificationIdString]) {
                    isNew = NO;
                    break;
                }
            }
            if(isNew) {
                NSMutableDictionary *dic = [@{@"identificationId":identificationIdString,@"name":userNameString}mutableCopy];
                [registeredPlayersArray addObject:dic];
                [tableView reloadData];
                [self initBackground];
            }
        }
    }
}

-(void)gotAllReceiveMessage:(NSInteger)id {
    if(id == memberAllCheckId) {
        BWSettingScene *scene = [BWSettingScene sceneWithSize:self.size];
        [scene sendPlayerInfo:registeredPlayersArray];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
}

@end
