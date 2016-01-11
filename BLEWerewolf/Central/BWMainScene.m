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


@implementation BWMainScene {
    SKSpriteNode *backgroundNode;

    BWCentralManager *centralManager;
    
    BWGorgeousTableView *table;
    NSMutableArray *gameIdArray;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    [self initBackground];
    
    centralManager = [BWCentralManager sharedInstance];
    centralManager.delegate = self;
    
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
    
    NSString *name = gameIdArray[indexPath.row];
    
    cell.textLabel.text = name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *touchedGameId = [gameIdArray[indexPath.row] substringToIndex:6];
    [centralManager setGameId:touchedGameId];
    //ここでgameIdを確定させる
    [centralManager stopScan];
    NSString *sendMessage = [NSString stringWithFormat:@"participateRequest:%@/%@/%@",touchedGameId,[BWUtility getIdentificationString],[BWUtility getUserName]];
    [centralManager sendNormalMessage:sendMessage interval:5.0 timeOut:15.0 firstWait:0.0];
    
    BWWaitConnectionScene *scene = [BWWaitConnectionScene sceneWithSize:self.size];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
    [self.view presentScene:scene transition:transition];
}

#pragma mark - BWCentralManagerDelegate

-(void)didReceivedMessage:(NSString *)message {
    //serveId:NNNNNN/S...S
    if([[BWUtility getCommand:message] isEqualToString:@"serveId"]) {
        NSArray *array = [BWUtility getCommandContents:message];
        NSString *gameId = array[0];
        NSString *hostName = array[1];
    
        BOOL isNew = YES;
        for(NSInteger i=0;i<gameIdArray.count;i++) {
            if([[gameIdArray[i] substringToIndex:6] isEqualToString:gameId]) {
                isNew = NO;
                break;
            }
        }
        if(isNew) {
            [gameIdArray addObject:[NSString stringWithFormat:@"%@(%@)",gameId,hostName]];
            [table.tableView reloadData];
        }
    }
}


@end
