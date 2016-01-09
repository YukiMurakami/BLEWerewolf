//
//  LWPickerTableScene.m
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/11/23.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import "LWPickerTableScene.h"

@interface LWPickerTableScene () <UITableViewDataSource,UITableViewDelegate> {
    UITableView *table;
}


@end

@implementation LWPickerTableScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    return self;
}

-(void)initBackgroundScene {
    
    SKSpriteNode *background = [[SKSpriteNode alloc]initWithImageNamed:@"night.jpg"];
    background.size = self.size;
    background.position = CGPointMake(self.size.width/2,self.size.height/2);
    [self addChild:background];
 
    CGFloat margin = self.size.width*0.8/5*0.25;
    
    table = [[UITableView alloc]initWithFrame:CGRectMake(self.size.width*0.1,22+margin,self.size.width*0.8,self.size.height - (22 + margin*3))];
    table.delegate = self;
    table.dataSource = self;
    table.rowHeight = table.frame.size.height/8;
}



-(void)willMoveFromView:(SKView *)view {
    [table removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    
    [self.view addSubview:table];
    [table reloadData];
}






#pragma mark -
#pragma mark tableDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.maxNumber+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d人",indexPath.row];
    
    return cell;
}

-(void)tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.toBackScene setCount:self.backRow count:indexPath.row];
    [table removeFromSuperview];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
    [self.view presentScene:self.toBackScene transition:transition];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

-(NSString *)tableView: (UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"%@の人数を選択してください",self.rollString];
}

@end
