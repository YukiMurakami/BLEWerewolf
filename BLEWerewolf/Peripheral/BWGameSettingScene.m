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
#import "BWWaitConnectionScene.h"
#import "BWTransferManager.h"

#import "LWBonjourManager.h"

const NSInteger limitNumberParticipate = 10;

typedef NS_ENUM(NSInteger,UserType) {
    UserTypeServerMember,
    UserTypeServer,
    UserTypeSubServer,
    UserTypeSubServerMember,
};

@interface BWGameSettingScene () {
    BWPeripheralManager *manager;
    BWCentralManager *centralManager;
    
    NSInteger gameId;
    
    BWGorgeousTableView *tableView;
    NSMutableArray *registeredPlayersArray;//自分のセントラル参加者
    NSMutableArray *registeredSubServerArray;//自分のサブサーバ（メインサーバのみ）
    NSMutableArray *registeredAllPlayersArray;//それ込みでの全ての参加者（メインサーバのみ）
    
    BWButtonNode *bwbuttonNode;
    
    NSInteger sendGlobalId;

    NSMutableDictionary *checkList;
    
    NSMutableDictionary *checkFinishList;
}

@end

@implementation BWGameSettingScene

-(id)initWithSize:(CGSize)size gameId:(NSInteger)_gameId {
    self = [super initWithSize:size];
    
    gameId = _gameId;
    
    manager = [BWPeripheralManager sharedInstance];
    
    manager.delegate = self;
    
    
    registeredPlayersArray = [NSMutableArray array];
    
    if(![BWUtility isSubPeripheral]) {
        //メインサーバ
        registeredSubServerArray = [NSMutableArray array];
        registeredAllPlayersArray = [NSMutableArray array];
        
        [[LWBonjourManager sharedManager] searchNetService];
        
        [NSObject performBlock:^{
            [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"-1/-/GM/-/通信テストOK"]];
        } afterDelay:3.0];
        
        
    } else {
        centralManager = [BWCentralManager sharedInstance];
        centralManager.delegate = self;
    }
    
    checkList = [NSMutableDictionary dictionary];
    
    //まずは自分を追加
    UserType type = UserTypeServer;
    if([BWUtility isSubPeripheral]) type = UserTypeSubServer;
    NSMutableDictionary *dic = [@{@"identificationId":[BWUtility getIdentificationString],@"name":[BWUtility getUserName],@"type":@(type)}mutableCopy];
    [registeredPlayersArray addObject:dic];
    if(![BWUtility isSubPeripheral]) {
        [registeredAllPlayersArray addObject:dic];
    }
    
    [self initBackground];
    
    [self startAdvertisingGameRoom];
    
    return self;
}

-(void)startAdvertisingGameRoom {
    //・ゲーム部屋のID通知「serveId:NNNNNN/P..P/S...S」 NNNNNNは６桁のゲームID（部屋生成時に自動的に生成）、P..P、S...SはペリフェラルのID,ユーザ名
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@/%@",(long)gameId,[BWUtility getIdentificationString],[BWUtility getUserName]];
    sendGlobalId = [manager sendGlobalSignalMessage:message interval:3.0];
}

-(void)stopAdvertisingGameRoom {
    [manager stopGlobalSignal:sendGlobalId];
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
    
    NSInteger playerNumber = registeredPlayersArray.count;
    if(![BWUtility isSubPeripheral]) {
        playerNumber = registeredAllPlayersArray.count;
    }
    SKSpriteNode *numberNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.3, self.size.width*0.8/5) title:[NSString stringWithFormat:@"%d人",(int)playerNumber]];
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
        //tableView.tableView.allowsSelection = NO;
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
    if(![BWUtility isSubPeripheral]) {
        return registeredAllPlayersArray.count;
    }
    return registeredPlayersArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(![BWUtility isSubPeripheral]) {
        //TODO::メインサーバ用の表示にする
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (!cell) {
            UserType type = [registeredAllPlayersArray[indexPath.row][@"type"]integerValue];
            NSInteger colorid = 0;
            if(type == UserTypeServer) colorid = 1;
            if(type == UserTypeServerMember) colorid = 0;
            if(type == UserTypeSubServer) colorid = 2;
            if(type == UserTypeSubServerMember) colorid = 3;
            cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:colorid];
        }
        
        NSString *name = registeredAllPlayersArray[indexPath.row][@"name"];
        
        cell.textLabel.text = name;
        if(indexPath.row == 0) cell.textLabel.text = [NSString stringWithFormat:@"%@ (gameId:%06d)",name,(int)gameId];
        
        //cell.backgroundView.alpha = 0.4;
        
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        NSInteger colorid = 2;
        if(indexPath.row == 0) colorid = 3;
        cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:colorid];
    }
    
    NSString *name = registeredPlayersArray[indexPath.row][@"name"];
    
    cell.textLabel.text = name;
    if(indexPath.row == 0) cell.textLabel.text = [NSString stringWithFormat:@"%@ (gameId:%06d)",name,(int)gameId];
    
    //cell.backgroundView.alpha = 0.4;
    
    return cell;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(![BWUtility isSubPeripheral]) {
        //TODO::メインサーバ用の処理を行う
        UserType type = [registeredAllPlayersArray[indexPath.row][@"type"]integerValue];
        if(type == UserTypeServerMember) {
            [registeredPlayersArray removeObject:registeredAllPlayersArray[indexPath.row]];
            [registeredAllPlayersArray removeObjectAtIndex:indexPath.row];
            [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            [self initBackground];
        }
    } else {
        if(indexPath.row != 0) {
            [registeredPlayersArray removeObjectAtIndex:indexPath.row];
            [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            [self initBackground];
        }
    }
    
    if(![manager isSendingSignal]) {
        //ルーム信号発信が止まってたら再開
        [self startAdvertisingGameRoom];
    }
}



-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"next"]) {//nextボタンが押せるのはメインサーバのみ
        [manager stopGlobalSignal:sendGlobalId];
        
        [bwbuttonNode removeFromParent];
        
        NSMutableArray *centralIds = [NSMutableArray array];
        
        for(NSInteger i=1;i<registeredAllPlayersArray.count;i++) {
            [checkList setObject:@NO forKey:registeredAllPlayersArray[i][@"identificationId"]];
        }
        for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
            [centralIds addObject:registeredPlayersArray[i][@"identificationId"]];
        }
        //ここで接続しているセントラルを確定させる
        [BWUtility setCentralIdentifications:centralIds];
        
        //セントラルに締め切りを通知する
        if(registeredSubServerArray.count <= 0) {
            [self sendPlayerInfos];
        } else {
            checkFinishList = [NSMutableDictionary dictionary];
            for(NSInteger i=0;i<registeredSubServerArray.count;i++) {
                [checkFinishList setObject:@NO forKey:registeredSubServerArray[i][@"identificationId"]];
            }
            for(NSInteger i=0;i<registeredSubServerArray.count;i++) {
                NSString *toIdentificationId = registeredSubServerArray[i][@"identificationId"];
                //・サブサーバが接続されてる場合は、接続締め切り信号を送る「participateFinish:」
                [manager sendNormalMessage:@"participateFinish:" toIdentificationId:toIdentificationId interval:5.0 timeOut:100.0 firstWait:0.02*i];
            }
        }
    }
}

-(void)sendPlayerInfos {
    NSMutableArray *messagesAndIdentificationIds = [NSMutableArray array];
    //これ以降は全ての端末が仮想的にメインサーバと接続されているかのように通信する。
    //member:0/A..A/S..S/12
    for(NSInteger i=1;i<registeredAllPlayersArray.count;i++) {
        NSString *toIdentificationId = registeredAllPlayersArray[i][@"identificationId"];
        for(NSInteger j=0;j<registeredAllPlayersArray.count;j++) {
            NSString *identificationId = registeredAllPlayersArray[j][@"identificationId"];
            NSString *message = [NSString stringWithFormat:@"member:%d/%@/%@/%d",(int)j,identificationId,registeredAllPlayersArray[j][@"name"],(int)registeredAllPlayersArray.count];
            [messagesAndIdentificationIds addObject:@{@"message":message,@"identificationId":toIdentificationId}];
        }
    }
    
    for(NSInteger i=0;i<messagesAndIdentificationIds.count;i++) {
        [manager sendNormalMessage:messagesAndIdentificationIds[i][@"message"] toIdentificationId:messagesAndIdentificationIds[i][@"identificationId"] interval:5.0 timeOut:100.0 firstWait:i*0.02];
    }
}

#pragma mark - BWPeripheralManagerDelegate
-(void)didReceiveMessage:(NSString *)message {
    //・ゲーム部屋に参加要求「participateRequest:NNNNNN/C..C/S...S/P..P/F」NNNNNNは６桁のゲームID、C..Cは16桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名,P..Pは接続先ペリフェラルID,Fは普通のセントラルなら0,サブサーバなら1
    if([[BWUtility getCommand:message] isEqualToString:@"participateRequest"]) {
        NSArray *params = [BWUtility getCommandContents:message];
        NSString *centralId = params[1];
        NSString *gameIdString = params[0];
        NSString *userNameString = params[2];
        NSString *peripheralId = params[3];
        BOOL isSubPeripheral = [params[4]boolValue];
        
        if(registeredPlayersArray.count < limitNumberParticipate) {
        
            if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]] && [peripheralId isEqualToString:[BWUtility getIdentificationString]]) {
                
                BOOL isNew = YES;
                for(NSInteger i=0;i<registeredPlayersArray.count;i++) {
                    if([registeredPlayersArray[i][@"identificationId"] isEqualToString:centralId]) {
                        isNew = NO;
                        break;
                    }
                }
                if(isNew) {
                    //participateAllow:A..A
                    [manager sendNormalMessage:[NSString stringWithFormat:@"participateAllow:%@",centralId] toIdentificationId:centralId interval:5.0 timeOut:100.0 firstWait:0.0];
                    
                    UserType type = UserTypeServerMember;
                    if([BWUtility isSubPeripheral]) {
                        type = UserTypeSubServerMember;
                    }
                    if(isSubPeripheral) {
                        type = UserTypeSubServer;
                    }
                    
                    NSMutableDictionary *dic = [@{@"identificationId":centralId,@"name":userNameString,@"type":@(type)}mutableCopy];
                    [registeredPlayersArray addObject:dic];
                    if(registeredPlayersArray.count >= limitNumberParticipate) {
                        [self stopAdvertisingGameRoom];
                    }
                    if(![BWUtility isSubPeripheral]) {
                        [registeredAllPlayersArray addObject:dic];
                        if(isSubPeripheral) {
                            [registeredSubServerArray addObject:dic];
                        }
                    }
                    
                    //[tableView.tableView reloadData];
                    [tableView.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:registeredPlayersArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                    [self initBackground];
                    
                    NSMutableArray *centralIds = [NSMutableArray array];
                    for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
                        [centralIds addObject:registeredPlayersArray[i][@"identificationId"]];
                    }
                    //ここで接続しているセントラルを確定させる
                    [BWUtility setCentralIdentifications:centralIds];
                    
                    
                    //・サブサーバ担当の参加者追加をサーバに通知「memberAddSubServer:NNNNNN/C..C/S..S/SubP..P」(P.Pはサブサーバ、C.C,S.Sはサブサーバのメンバ)
                    if([BWUtility isSubPeripheral]) {
                        NSString *mes = [NSString stringWithFormat:@"memberAddSubServer:%@/%@/%@/%@",gameIdString,centralId,userNameString,[BWUtility getIdentificationString]];
                        [centralManager sendNormalMessage:mes interval:5.0 timeOut:100.0 firstWait:0.0];
                    }
                    
                }
            }
            
        }
    }
    
    //・サブサーバ担当の参加者追加をサーバに通知「memberAddSubServer:NNNNNN/C..C/S..S/SubP..P」(subP.Pはサブサーバ、C.C,S.Sはサブサーバのメンバ)
    if(![BWUtility isSubPeripheral]) {
        if([[BWUtility getCommand:message] isEqualToString:@"memberAddSubServer"]) {
            NSArray *array = [BWUtility getCommandContents:message];
            NSString *gameIdString = array[0];
            NSString *centralId = array[1];
            NSString *userNameString = array[2];
            NSString *subPeripheralId = array[3];
            
            BOOL isFoundSubPeripheral = NO;
            for(NSInteger i=0;i<registeredSubServerArray.count;i++) {
                if([registeredSubServerArray[i][@"identificationId"] isEqualToString:subPeripheralId]) {
                    isFoundSubPeripheral = YES;
                    break;
                }
            }
            
            if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]] && isFoundSubPeripheral) {
                
                BOOL isNew = YES;
                for(NSInteger i=0;i<registeredAllPlayersArray.count;i++) {
                    if([registeredAllPlayersArray[i][@"identificationId"] isEqualToString:centralId]) {
                        isNew = NO;
                        break;
                    }
                }
                if(isNew) {
                    NSMutableDictionary *dic = [@{@"identificationId":centralId,@"name":userNameString,@"type":@(UserTypeSubServerMember)}mutableCopy];
                    [registeredAllPlayersArray addObject:dic];
                    
                    [tableView.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:registeredAllPlayersArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                    [self initBackground];
                }
            }
        }
    }
    
    //・参加者情報受信完了通知「memberCheck:C..C」
    if([[BWUtility getCommand:message] isEqualToString:@"memberCheck"]) {
        NSString *centralId = [BWUtility getCommandContents:message][0];
        checkList[centralId] = @YES;
        
        BOOL isAllOK = YES;
        for(id isOK in [checkList objectEnumerator]) {
            if(![isOK boolValue]) {
                isAllOK = NO;
                break;
            }
        }
        if(isAllOK) {
            BWSettingScene *scene = [BWSettingScene sceneWithSize:self.size];
            [scene sendPlayerInfo:registeredAllPlayersArray];
            SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
            [self.view presentScene:scene transition:transition];
        }
    }
    
    
    //ゲーム部屋から退出通知（タイムアウトなど）「participateCancel:NNNNNN/C..C」
    if([[BWUtility getCommand:message] isEqualToString:@"participateCancel"]) {
        NSArray *params = [BWUtility getCommandContents:message];
        NSString *centralId = params[1];
        NSString *gameIdString = params[0];
        if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]]) {
            for(NSInteger i=0;i<registeredPlayersArray.count;i++) {
                if([registeredPlayersArray[i][@"identificationId"] isEqualToString:centralId]) {
                    [registeredPlayersArray removeObjectAtIndex:i];
                    [tableView.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
                    [self initBackground];
                    break;
                }
            }
        }
    }
    
    //・締め切り終了確認を通知する「checkParticipateFinish:C..C」（C..CはサブサーバのセントラルID) (サブサーバから送られてくる）
    if(![BWUtility isSubPeripheral]) {
        if([[BWUtility getCommand:message] isEqualToString:@"checkParticipateFinish"]) {
            NSString *subPeripheralId = [BWUtility getCommandContents:message][0];
            checkFinishList[subPeripheralId] = @YES;
            
            BOOL isAllOK = YES;
            for(NSString *key in checkFinishList) {
                if(![checkFinishList[key]boolValue]) {
                    isAllOK = NO;
                    break;
                }
            }
            if(isAllOK) {
                [self sendPlayerInfos];
            }
        }
    }
}

#pragma mark - BWCentralManagerDelegate
-(void)didReceivedMessage:(NSString *)message {
    if([BWUtility isSubPeripheral]) {
        //・サブサーバが接続されてる場合は、接続締め切り信号を送る「participateFinish:」（メインサーバから送られてくる）
        if([[BWUtility getCommand:message] isEqualToString:@"participateFinish"]) {
            //ここで接続終了
            //サブサーバはメインサーバに通知を送り、あとは基本的にセントラルと同じ動きをし、信号の中継のみを行う。
            [BWUtility setSubPeripheralTranferFlag:YES];
            
            //・締め切り終了確認を通知する「checkParticipateFinish:C..C」（C..CはサブサーバのセントラルID)
            NSString *sendMessage = [NSString stringWithFormat:@"checkParticipateFinish:%@",[BWUtility getIdentificationString]];
            [centralManager sendNormalMessage:sendMessage interval:5.0 timeOut:100.0 firstWait:0.0];
            
            //中継用のシングルトンを生成
            [BWTransferManager sharedInstance];
            
            BWWaitConnectionScene *scene = [BWWaitConnectionScene sceneWithSize:self.size];
            [scene setPrintMessage:@"プレイヤー情報受信中"];
            SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
            [self.view presentScene:scene transition:transition];
        }
    }
}

@end
