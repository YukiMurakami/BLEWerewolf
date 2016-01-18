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

const NSInteger connectLimit = 4;

typedef NS_ENUM(NSInteger,UserType) {
    UserTypeServerMember,
    UserTypeServer,
    UserTypeSubServer,
    UserTypeSubServerMember,
};

@interface BWGameSettingScene () {
    BWPeripheralManager *manager;
    BWCentralManager *centralmanager;
    
    NSInteger gameId;
    
    BWGorgeousTableView *tableView;
    NSMutableArray *registeredPlayersArray;
    NSMutableArray *registeredSubServerArray;
    NSMutableArray *registeredAllPlayersArray;
    
    BWButtonNode *bwbuttonNode;
    
    NSInteger sendGlobalId;
    NSInteger memberAllCheckId;
    
    BOOL isFinishRequest;
    BOOL isAllCentralReady;
    
    
    
    
    //サブサーバ用
    NSMutableArray *playerInfos;
}

@end

@implementation BWGameSettingScene

-(id)initWithSizeAndGameid:(CGSize)size :(NSInteger)id {
    self = [super initWithSize:size];
    
    gameId = id;
    
    manager = [BWPeripheralManager sharedInstance];
    
    manager.delegate = self;
    
    //サブサーバはセントラルも使う
    centralmanager = [BWCentralManager sharedInstance];
    centralmanager.delegate = self;
    playerInfos = [NSMutableArray array];
    
    isFinishRequest = NO;
    isAllCentralReady = NO;
    
    registeredPlayersArray = [NSMutableArray array];
    registeredAllPlayersArray = [NSMutableArray array];
    
    //まずは自分を追加
    NSMutableDictionary *dic = [@{@"identificationId":[BWUtility getIdentificationString],@"name":[BWUtility getUserName],@"type":@(UserTypeSubServer)}mutableCopy];
    [registeredPlayersArray addObject:dic];
    [registeredAllPlayersArray addObject:dic];
    
    [self initBackground];
    
    //serveId:NNNNNN/S...S/B...B
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@/%@",(long)gameId,[BWUtility getUserName],[BWUtility getIdentificationString]];
    sendGlobalId = [manager sendGlobalSignalMessage:message interval:3.0];
    
    return self;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    gameId = [BWUtility getRandInteger:1000000];
    
    manager = [BWPeripheralManager sharedInstance];
    
    manager.delegate = self;
    
    isFinishRequest = NO;
    isAllCentralReady = NO;
    
    registeredPlayersArray = [NSMutableArray array];
    registeredSubServerArray = [NSMutableArray array];
    registeredAllPlayersArray = [NSMutableArray array];
    
    //まずは自分を追加
    NSMutableDictionary *dic = [@{@"identificationId":[BWUtility getIdentificationString],@"name":[BWUtility getUserName],@"type":@(UserTypeServer)}mutableCopy];
    [registeredPlayersArray addObject:dic];
    [registeredAllPlayersArray addObject:dic];
    
    [self initBackground];
    
    //serveId:NNNNNN/S...S/B...B
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@/%@",(long)gameId,[BWUtility getUserName],[BWUtility getIdentificationString]];
    sendGlobalId = [manager sendGlobalSignalMessage:message interval:3.0];
    
    return self;
}

-(void)initBackground {
    self.backgroundColor = [UIColor blueColor];
    
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    backgroundNode.size = CGSizeMake(self.size.width, self.size.height);
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:backgroundNode];
    
    NSString *title = @"プレイヤー登録画面";
    if([BWUtility isSubPeripheral]) title = @"サブサーバ";
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.8, self.size.width*0.8/4) title:title];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - self.size.width*0.1);
    [backgroundNode addChild:titleNode];
    
    SKSpriteNode *numberNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.3, self.size.width*0.8/5) title:[NSString stringWithFormat:@"%d人",(int)registeredAllPlayersArray.count]];
    numberNode.position = CGPointMake(0, titleNode.position.y - titleNode.size.height/2 - numberNode.size.height/2 - self.size.width*0.1/2);
    
    [backgroundNode addChild:numberNode];
    
    CGFloat margin = self.size.height * 0.05;
    
    if(![BWUtility isSubPeripheral]) {
    
        bwbuttonNode = [[BWButtonNode alloc]init];
        [bwbuttonNode makeButtonWithSize:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"next" title:@"参加締め切り" boldRate:1.0];
        bwbuttonNode.position = CGPointMake(0, -self.size.height/2+margin+self.size.width*0.2*0.7/2);
        bwbuttonNode.delegate = self;
        [backgroundNode addChild:bwbuttonNode];
    }
    
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

    return registeredAllPlayersArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        
        cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:[registeredAllPlayersArray[indexPath.row][@"type"]integerValue]];
    }
    
    NSString *name = registeredAllPlayersArray[indexPath.row][@"name"];
    
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
        
        isFinishRequest = YES;
        
        NSMutableArray *centralIds = [NSMutableArray array];
        for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
            [centralIds addObject:registeredPlayersArray[i][@"identificationId"]];
        }
        [BWUtility setCentralIdentifications:centralIds];
        
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
    //・ゲーム部屋に参加要求「participateRequest:NNNNNN/A..A/S...S/P..P/F」NNNNNNは６桁のゲームID、A..Aは16桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名,P..Pは接続先ペリフェラルID,Fは普通のセントラルなら0,サブサーバなら1
    if([[BWUtility getCommand:message] isEqualToString:@"participateRequest"]) {
        
        if(isFinishRequest) return;
        
        NSArray *params = [BWUtility getCommandContents:message];
        NSString *identificationIdString = params[1];
        NSString *gameIdString = params[0];
        NSString *userNameString = params[2];
        NSString *peripheralId = params[3];
        BOOL isSubServer = (BOOL)[params[4]integerValue];
        
        if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]] && [peripheralId isEqualToString:[BWUtility getIdentificationString]]) {
            
            BOOL isNew = YES;
            for(NSInteger i=0;i<registeredPlayersArray.count;i++) {
                if([registeredPlayersArray[i][@"identificationId"] isEqualToString:identificationIdString]) {
                    isNew = NO;
                    break;
                }
            }
            if(isNew && registeredPlayersArray.count < connectLimit) {
                UserType type = UserTypeServerMember;
                if(isSubServer) type = UserTypeSubServer;
                NSMutableDictionary *dic = [@{@"identificationId":identificationIdString,@"name":userNameString,@"type":@(type)}mutableCopy];
                [registeredPlayersArray addObject:dic];
                [registeredAllPlayersArray addObject:dic];
                if(isSubServer) {
                    NSMutableArray *subserversPlayers = [NSMutableArray array];
                    NSMutableDictionary *dic2 = [@{@"identificationId":identificationIdString,@"flag":@NO,@"member":subserversPlayers}mutableCopy];
                    [registeredSubServerArray addObject:dic2];
                }
                NSInteger insertIndex = registeredAllPlayersArray.count-1;
                [tableView.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:insertIndex inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                //[tableView.tableView reloadData];
                [self initBackground];
                NSMutableArray *centralIds = [NSMutableArray array];
                for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
                    [centralIds addObject:registeredPlayersArray[i][@"identificationId"]];
                }
                [BWUtility setCentralIdentifications:centralIds];
                
                if([BWUtility isSubPeripheral]) {
                    //サブサーバはサーバに参加者追加の通知を送信する
                    //・サブサーバ担当の参加者追加をサーバに通知「memberAddSubServer:NNNNNN/C..C/S..S/P..P」(P.Pはサブサーバ、C.C,S.Sはサブサーバのメンバ)
                    NSString *addMemberMessage = [NSString stringWithFormat:@"memberAddSubServer:%06ld/%@/%@/%@",(long)gameId,identificationIdString,userNameString,[BWUtility getIdentificationString]];
                    [centralmanager sendNormalMessage:addMemberMessage interval:5.0 timeOut:20.0 firstWait:0.0];
                }
                
                //participateAllow:C..C
                [manager sendNormalMessage:[NSString stringWithFormat:@"participateAllow:%@",identificationIdString] toIdentificationId:identificationIdString interval:5.0 timeOut:15.0 firstWait:0.0];
            }
            
            if(registeredPlayersArray.count >= connectLimit) {
                [manager stopAd];
            }
        }
    }
    
    //・サブサーバ担当の参加者追加をサーバに通知「memberAddSubServer:NNNNNN/C..C/S..S/P..P」(P.Pはサブサーバ、C.C,S.Sはサブサーバのメンバ)
    if([[BWUtility getCommand:message] isEqualToString:@"memberAddSubServer"]) {
        if(isFinishRequest) return;
        
        NSArray *params = [BWUtility getCommandContents:message];
        NSString *identificationIdString = params[1];
        NSString *gameIdString = params[0];
        NSString *userNameString = params[2];
        NSString *subServerIdentification = params[3];
        
        if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]]) {
            
            BOOL isNew = YES;
            for(NSInteger i=0;i<registeredAllPlayersArray.count;i++) {
                if([registeredAllPlayersArray[i][@"identificationId"] isEqualToString:identificationIdString]) {
                    isNew = NO;
                    break;
                }
            }
            if(isNew) {
                UserType type = UserTypeSubServerMember;
                NSMutableDictionary *dic = [@{@"identificationId":identificationIdString,@"name":userNameString,@"type":@(type)}mutableCopy];
                
                NSInteger index = -1;
                for(NSInteger i=0;i<registeredSubServerArray.count;i++) {
                    if([registeredSubServerArray[i][@"identificationId"] isEqualToString:subServerIdentification]) {
                        [registeredSubServerArray[i][@"member"] addObject:dic];
                        index = i;
                        break;
                    }
                }
                NSInteger insertIndex = -1;
                for(NSInteger i=0;i<registeredAllPlayersArray.count;i++) {
                    if([registeredAllPlayersArray[i][@"identificationId"] isEqualToString:subServerIdentification]) {
                        [registeredAllPlayersArray insertObject:dic atIndex:i+1];
                        insertIndex = i+1;
                        break;
                    }
                }
                
                [tableView.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:insertIndex inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                //[tableView.tableView reloadData];
                [self initBackground];
            }
        }
    }
    
    //・サブサーバ担当のセントラル全員にプレイヤー情報を送信完了したことをペリフェラル（サーバ）に通知「memberCheckSubServer:NNNNNN/C..C/P..P」
    if([[BWUtility getCommand:message] isEqualToString:@"memberCheckSubServer"]) {
        NSArray *params = [BWUtility getCommandContents:message];
        NSString *centralId = params[1];
        NSString *gameIdString = params[0];
        NSString *peripheralId = params[2];
       
        if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]] && [peripheralId isEqualToString:[BWUtility getIdentificationString]]) {
            for(NSInteger i=0;i<registeredSubServerArray.count;i++) {
                if(![registeredSubServerArray[i][@"identificationId"] isEqualToString:centralId]) {
                    registeredSubServerArray[i][@"flag"] = @YES;
                }
            }
            
            [self checkAllSubServer];
        }
    }
}

-(void)gotAllReceiveMessage:(NSInteger)id {
    if(id == memberAllCheckId) {
        isAllCentralReady = YES;
        [self checkAllSubServer];
    }
}

-(void)checkAllSubServer {
    
    if(!isAllCentralReady) return;
    
    for(NSInteger i=0;i<registeredSubServerArray.count;i++) {
        if(![registeredSubServerArray[i][@"flag"]boolValue]) {
            return;
        }
    }
    
    BWSettingScene *scene = [BWSettingScene sceneWithSize:self.size];
    [scene sendPlayerInfo:registeredPlayersArray];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
    [self.view presentScene:scene transition:transition];
}

#pragma mark - centralDelegate
-(void)didReceivedMessage:(NSString *)message {
    //central サブサーバ用
    //member:0/A..A/S..S/12/
/*
    if([[BWUtility getCommand:message] isEqualToString:@"member"]) {
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
        
        BOOL isAllReceived = YES;
        for(NSInteger i=0;i<playerInfos.count;i++) {
            if([playerInfos[i][@"identificationId"] isEqualToString:@""]) {
                isAllReceived = NO;
                break;
            }
        }
        if(isAllReceived) {
            printMessage = @"ルール設定待ち";
            [self initBackground];
        }
    }
 */
}

@end
