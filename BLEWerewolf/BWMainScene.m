//
//  BWMainScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/28.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWMainScene.h"
#import "BWUtility.h"


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


@end
