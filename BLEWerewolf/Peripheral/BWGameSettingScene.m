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
    
    BWGorgeousTableView *tableView;
    NSMutableArray *registeredPlayersArray;
    
    BWButtonNode *bwbuttonNode;
    
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
    
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@",(long)gameId,[BWUtility getUserName]];
    sendGlobalId = [manager sendGlobalSignalMessage:message interval:3.0];
    
    return self;
}

-(void)initBackground {
    self.backgroundColor = [UIColor blueColor];
    
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    backgroundNode.size = CGSizeMake(self.size.width, self.size.height);
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:backgroundNode];
    
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.8, self.size.width*0.8/4) title:@"プレイヤー登録画面"];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - self.size.width*0.1);
    [backgroundNode addChild:titleNode];
    
    SKSpriteNode *numberNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.3, self.size.width*0.8/5) title:[NSString stringWithFormat:@"%d人",(int)registeredPlayersArray.count]];
    numberNode.position = CGPointMake(0, titleNode.position.y - titleNode.size.height/2 - numberNode.size.height/2 - self.size.width*0.1/2);
    
    [backgroundNode addChild:numberNode];
    
    CGFloat margin = self.size.height * 0.05;
    
    bwbuttonNode = [[BWButtonNode alloc]init];
    [bwbuttonNode makeButtonWithSize:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"next" title:@"参加締め切り" boldRate:1.0];
    bwbuttonNode.position = CGPointMake(0, -self.size.height/2+margin+self.size.width*0.2*0.7/2);
    bwbuttonNode.delegate = self;
    [backgroundNode addChild:bwbuttonNode];
    
    if(!tableView) {
        tableView = [[BWGorgeousTableView alloc]initWithFrame:CGRectMake(margin, titleNode.size.height+numberNode.size.height+margin*2.2, self.size.width-margin*2, self.size.height - (titleNode.size.height+numberNode.size.height+margin*2.2 + margin*2+bwbuttonNode.size.height))];
        [tableView setViewDesign:self];
        tableView.tableView.rowHeight = tableView.tableView.frame.size.height/6;
        tableView.tableView.allowsSelection = NO;
    }
    
    
}


-(void)willMoveFromView:(SKView *)view {
    [tableView removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    
    [self.view addSubview:tableView];
    [tableView.tableView reloadData];
}

#pragma mark - tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return registeredPlayersArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        NSInteger colorid = 0;
        if(indexPath.row == 0) colorid = 1;
        cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:colorid];
    }
    
    NSString *name = registeredPlayersArray[indexPath.row][@"name"];
    
    cell.textLabel.text = name;
    if(indexPath.row == 0) cell.textLabel.text = [NSString stringWithFormat:@"%@ (gameId:%06d)",name,(int)gameId];
    
    //cell.backgroundView.alpha = 0.4;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}



-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"next"]) {
        [manager stopGlobalSignal:sendGlobalId];
        
        [bwbuttonNode removeFromParent];
        
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
        [manager sendNormalMessage:[NSString stringWithFormat:@"participateAllow:%@",identificationIdString] toIdentificationId:identificationIdString interval:5.0 timeOut:15.0 firstWait:0.0];
        
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
                [tableView.tableView reloadData];
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
