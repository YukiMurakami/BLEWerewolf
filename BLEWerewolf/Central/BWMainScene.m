//
//  BWMainScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/28.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWMainScene.h"
#import "BWUtility.h"
#import "BWWaitConnectionScene.h"
#import "BWGorgeousTableView.h"
#import "BWGameSettingScene.h"


@implementation BWMainScene {
    SKSpriteNode *backgroundNode;

    BWSocketManager *socketManager;
    
    BWGorgeousTableView *table;
    NSMutableArray *gameIdArray;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    [self initBackground];
    
    socketManager = [BWSocketManager sharedInstance];
    [socketManager setIsPeripheralParams:NO];
    socketManager.delegate = self;
    
    gameIdArray = [NSMutableArray array];
    
    return self;
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2,self.size.height/2);
    [self addChild:backgroundNode];
    
    CGFloat margin = self.size.width*0.1;

    
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width - margin*2, (self.size.width-margin*2)/4) title:@"ゲーム部屋一覧"];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - margin);
    [backgroundNode addChild:titleNode];
    
    
    table = [[BWGorgeousTableView alloc]initWithFrame:CGRectMake(margin,titleNode.size.height + margin*2,self.size.width-margin*2,self.size.height-margin*3-titleNode.size.height)];
    [table setViewDesign:self];
    table.tableView.rowHeight = table.frame.size.height/6;
}

-(void)willMoveFromView:(SKView *)view {
    [table removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    
    [self.view addSubview:table];
    [table.tableView reloadData];
}

#pragma mark - tableDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return gameIdArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:0];
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    NSString *name = [NSString stringWithFormat:@"%@(%@)",gameIdArray[indexPath.row][@"name"],gameIdArray[indexPath.row][@"gameId"]];
    
    cell.textLabel.text = name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *touchedGameId = gameIdArray[indexPath.row][@"gameId"];
    NSString *peripheralIdentificationId = gameIdArray[indexPath.row][@"identificationId"];
    
    [BWUtility saveNowGameIdString:touchedGameId];
    //ここでgameId,peripheralIdを確定させる
    [socketManager setPeripheralId:peripheralIdentificationId];
    
    //・ゲーム部屋に参加要求「participateRequest:NNNNNN/C..C/S...S/P..P/F」NNNNNNは６桁のゲームID、C..Cは16桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名,P..Pは接続先ペリフェラルID,Fは普通のセントラルなら0,サブサーバなら1
    //今はサブサーバはなし
    NSString *sendMessage = [NSString stringWithFormat:@"participateRequest:%@/%@/%@/%@/0",touchedGameId,[BWUtility getIdentificationString],[BWUtility getUserName],peripheralIdentificationId];
    [socketManager sendMessageForPeripheral:sendMessage];
        
    BWWaitConnectionScene *scene = [BWWaitConnectionScene sceneWithSize:self.size];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
    [self.view presentScene:scene transition:transition];
    
}

#pragma mark - MessageManager

- (void)didReceiveAdvertiseGameroomInfo:(NSDictionary *)gameroomInfo {
    //ペリフェラルのアドバタイズを受信
    NSString *gameId = gameroomInfo[@"gameId"];
    NSString *peripheralId = gameroomInfo[@"peripheralId"];
    NSString *peripheralName = gameroomInfo[@"peripheralName"];
    
    BOOL isNew = YES;
    for(NSInteger i=0;i<gameIdArray.count;i++) {
        if([[gameIdArray[i][@"gameId"] substringToIndex:6] isEqualToString:gameId]) {
            isNew = NO;
            break;
        }
    }
    if(isNew) {
        NSMutableDictionary *dic = [@{@"gameId":gameId,@"identificationId":peripheralId,@"name":peripheralName}mutableCopy];
        [gameIdArray addObject:dic];
        [table.tableView reloadData];
    }
}

@end
