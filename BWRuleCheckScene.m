//
//  BWRuleCheckScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWRuleCheckScene.h"
#import "BWUtility.h"

@implementation BWRuleCheckScene {
    BOOL isCheck;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    isCheck = NO;
    
    [self initBackground];
    
    return self;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic {
    isPeripheral = _isPeripheral;
    
    infoDic = _infoDic;
    
    if(isPeripheral) {
        peripheralManager = [BWPeripheralManager sharedInstance];
        peripheralManager.delegate = self;
    } else {
        centralManager = [BWCentralManager sharedInstance];
        centralManager.delegate = self;
    }
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    [self addChild:backgroundNode];

    CGFloat margin = self.size.height * 0.05;
    
    SKLabelNode *labelNode = [[SKLabelNode alloc]init];
    labelNode.fontSize = 30.0;
    labelNode.position = CGPointMake(0,self.size.height/2 - labelNode.fontSize - margin);
    labelNode.text = @"ルール";
    labelNode.fontColor = [UIColor blackColor];
    [backgroundNode addChild:labelNode];
    
    if(!isCheck) {
        SKSpriteNode *buttonNode = [BWUtility makeButton:@"確認" size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"next" position:CGPointMake(0, -self.size.height/2+margin+self.size.width*0.2*0.7/2)];
        [backgroundNode addChild:buttonNode];
    }
    
    tableView = [[UITableView alloc]initWithFrame:CGRectMake(margin,labelNode.fontSize + margin*2,self.size.width-margin*2,self.size.height-margin*3-labelNode.fontSize)];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = tableView.frame.size.height/6;
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
    return 1 + [[infoDic[@"rules"] allKeys] count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    if(indexPath.row == 0) {
        cell.textLabel.text = @"配役";
        cell.detailTextLabel.text = [BWUtility getRoleSetString:infoDic[@"roles"]];
    }
    if(indexPath.row == 1) {
        cell.textLabel.text = @"昼時間";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@分",infoDic[@"rules"][@"timer"]];
    }
    if(indexPath.row == 2) {
        cell.textLabel.text = @"夜時間";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@分",infoDic[@"rules"][@"nightTimer"]];
    }
    if(indexPath.row == 3) {
        cell.textLabel.text = @"初日占い";
        cell.detailTextLabel.text = [BWUtility getFortuneButtonString:[infoDic[@"rules"][@"fortuneMode"]integerValue]];
    }
    if(indexPath.row == 4) {
        cell.textLabel.text = @"連続護衛";
        BOOL canGuard = [infoDic[@"rules"][@"canContinuousGuard"]boolValue];
        if(canGuard) {
            cell.detailTextLabel.text = @"あり";
        } else {
            cell.detailTextLabel.text = @"なし";
        }
    }
    if(indexPath.row == 5) {
        cell.textLabel.text = @"役かけ";
        BOOL isLack = [infoDic[@"rules"][@"isLacking"]boolValue];
        if(isLack) {
            cell.detailTextLabel.text = @"あり";
        } else {
            cell.detailTextLabel.text = @"なし";
        }
    }
    
    return cell;
}

-(void)didReceivedMessage:(NSString *)message {
    
}

@end
