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

const NSInteger limitNumberParticipate = 5;

@interface BWGameSettingScene () {
    BWPeripheralManager *manager;
    
    NSInteger gameId;
    
    BWGorgeousTableView *tableView;
    NSMutableArray *registeredPlayersArray;
    NSMutableArray *registeredSubServerArray;
    NSMutableArray *registeredAllPlayersArray;
    
    BWButtonNode *bwbuttonNode;
    
    NSInteger sendGlobalId;

    NSMutableDictionary *checkList;
}

@end

@implementation BWGameSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    gameId = [BWUtility getRandInteger:1000000];
    
    manager = [BWPeripheralManager sharedInstance];
    
    manager.delegate = self;
    
    
    registeredPlayersArray = [NSMutableArray array];
    
    checkList = [NSMutableDictionary dictionary];
    
    //まずは自分を追加
    NSMutableDictionary *dic = [@{@"identificationId":[BWUtility getIdentificationString],@"name":[BWUtility getUserName]}mutableCopy];
    [registeredPlayersArray addObject:dic];
    
    [self initBackground];
    
    
    //・ゲーム部屋のID通知「serveId:NNNNNN/P..P/S...S」 NNNNNNは６桁のゲームID（部屋生成時に自動的に生成）、P..P、S...SはペリフェラルのID,ユーザ名
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@/%@",(long)gameId,[BWUtility getIdentificationString],[BWUtility getUserName]];
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

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.row != 0) {
        [registeredPlayersArray removeObjectAtIndex:indexPath.row];
        [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        [self initBackground];
    }
}



-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"next"]) {
        [manager stopGlobalSignal:sendGlobalId];
        
        [bwbuttonNode removeFromParent];
        
        NSMutableArray *centralIds = [NSMutableArray array];
        
        for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
            [checkList setObject:@NO forKey:registeredPlayersArray[i][@"identificationId"]];
            [centralIds addObject:registeredPlayersArray[i][@"identificationId"]];
        }
        //ここで接続しているセントラルを確定させる
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
        
        for(NSInteger i=0;i<messagesAndIdentificationIds.count;i++) {
            [manager sendNormalMessage:messagesAndIdentificationIds[i][@"message"] toIdentificationId:messagesAndIdentificationIds[i][@"identificationId"] interval:5.0 timeOut:100.0 firstWait:i*0.02];
        }
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
                    
                    NSMutableDictionary *dic = [@{@"identificationId":centralId,@"name":userNameString}mutableCopy];
                    [registeredPlayersArray addObject:dic];
                    //[tableView.tableView reloadData];
                    [tableView.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:registeredPlayersArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                    [self initBackground];
                    
                    NSMutableArray *centralIds = [NSMutableArray array];
                    for(NSInteger i=1;i<registeredPlayersArray.count;i++) {
                        [centralIds addObject:registeredPlayersArray[i][@"identificationId"]];
                    }
                    //ここで接続しているセントラルを確定させる
                    [BWUtility setCentralIdentifications:centralIds];
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
            [scene sendPlayerInfo:registeredPlayersArray];
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
}

@end
