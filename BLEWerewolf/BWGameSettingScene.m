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

@interface BWGameSettingScene () {
    BWPeripheralManager *manager;
    
    NSInteger gameId;
    
    UITableView *tableView;
    NSMutableArray *registeredPlayersArray;
}

@end

@implementation BWGameSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    gameId = [BWUtility getRandInteger:1000000];
    
    manager = [BWPeripheralManager sharedInstance];
    
    registeredPlayersArray = [NSMutableArray array];
    
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
    title.text = [NSString stringWithFormat:@"プレイヤー登録画面（%d人）",registeredPlayersArray.count];
    SKLabelNode *title2 = [[SKLabelNode alloc]init];
    title2.fontSize = self.size.height*0.05;
    title2.text = [NSString stringWithFormat:@"ゲームID:%06ld",(long)gameId];
    title2.fontName = @"HiraKakuProN-W3";
    
    
    title.position = CGPointMake(0, self.size.height*0.4);
    title2.position = CGPointMake(0, self.size.height*0.3);
    [backgroundNode addChild:title];
    [backgroundNode addChild:title2];
    
    CGFloat margin = self.size.height * 0.05;
    tableView = [[UITableView alloc]initWithFrame:CGRectMake(margin, (title.fontSize+margin)*2, self.size.width-margin*2, self.size.height-margin*3-title.fontSize*2)];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = tableView.frame.size.height/6;
    
    NSString *message = [NSString stringWithFormat:@"receive:%06ld",(long)gameId];
    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(sendMessage:) userInfo:@{@"message":message} repeats:YES];
}

-(void)sendMessage:(NSTimer*)timer {
    [[BWPeripheralManager sharedInstance] updateSendMessage:[timer userInfo][@"message"]];
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

@end
