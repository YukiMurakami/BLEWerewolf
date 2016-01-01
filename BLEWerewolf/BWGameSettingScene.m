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
    
    manager.delegate = self;
    
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
    
    NSString *message = [NSString stringWithFormat:@"serveId:%06ld/%@",(long)gameId,[BWUtility getUserName]];
    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(sendMessage:) userInfo:@{@"message":message} repeats:YES];
}

-(void)sendMessage:(NSTimer*)timer {
    [[BWPeripheralManager sharedInstance] updateSendMessage:[timer userInfo][@"message"]];
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

#pragma mark - BWPeripheralManagerDelegate
-(void)didReceiveMessage:(NSString *)message {
    //participateRequest:NNNNNN/A..A(32)/S...S
    if(message.length >= 18 && [[message substringToIndex:18] isEqualToString:@"participateRequest"]) {
        NSString *identificationIdString = [message substringWithRange:NSMakeRange(26,32)];
        NSString *gameIdString = [message substringWithRange:NSMakeRange(19,6)];
        NSString *userNameString = [message substringFromIndex:59];
        
        if([gameIdString isEqualToString:[NSString stringWithFormat:@"%06ld",(long)gameId]]) {
            NSLog(@"接続要求:%@,%@",identificationIdString,userNameString);
            
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
            }
        }
    }
}

@end
