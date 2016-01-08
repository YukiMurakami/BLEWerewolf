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


@implementation BWMainScene {
    SKSpriteNode *backgroundNode;
    SKLabelNode *labelNode;
    BWCentralManager *centralManager;
    
    UITableView *table;
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
    
    CGFloat margin = self.size.height * 0.05;
    
    labelNode = [[SKLabelNode alloc]init];
    labelNode.fontSize = 30.0;
    labelNode.position = CGPointMake(0,self.size.height/2 - labelNode.fontSize - margin);
    labelNode.text = @"ゲーム部屋一覧";
    labelNode.fontColor = [UIColor blackColor];
    [backgroundNode addChild:labelNode];
    
    table = [[UITableView alloc]initWithFrame:CGRectMake(margin,labelNode.fontSize + margin*2,self.size.width-margin*2,self.size.height-margin*3-labelNode.fontSize)];
    table.delegate = self;
    table.dataSource = self;
    table.rowHeight = table.frame.size.height/6;
    
}

-(void)willMoveFromView:(SKView *)view {
    [table removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    
    [self.view addSubview:table];
    [table reloadData];
}

#pragma mark - tableDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return gameIdArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    NSString *name = gameIdArray[indexPath.row];
    
    cell.textLabel.text = name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *touchedGameId = [gameIdArray[indexPath.row] substringToIndex:6];
    [centralManager setGameId:touchedGameId];
    //ここでgameIdを確定させる
    NSString *sendMessage = [NSString stringWithFormat:@"participateRequest:%@/%@/%@",touchedGameId,[BWUtility getIdentificationString],[BWUtility getUserName]];
    [centralManager sendNormalMessage:sendMessage interval:1.0 timeOut:10.0];
    
    BWWaitConnectionScene *scene = [BWWaitConnectionScene sceneWithSize:self.size];
    [centralManager replaceSenderScene:&scene];
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
            [table reloadData];
        }
    }
}


@end
