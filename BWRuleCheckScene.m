//
//  BWRuleCheckScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWRuleCheckScene.h"
#import "BWUtility.h"
#import "BWRoleRotateScene.h"

@implementation BWRuleCheckScene {
    BOOL isCheck;
    NSMutableArray *checkList;
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
        checkList = [NSMutableArray array];
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            [checkList addObject:@NO];
        }
        
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
    } else {
        SKLabelNode *checkedLabelNode = [[SKLabelNode alloc]init];
        checkedLabelNode.text = @"全員の確認待ち";
        checkedLabelNode.fontColor = [UIColor blackColor];
        checkedLabelNode.fontSize = self.size.width*0.2*0.7*0.7;
        checkedLabelNode.position = CGPointMake(0, -self.size.height/2+margin+self.size.width*0.2*0.7/2);
        [backgroundNode addChild:checkedLabelNode];
    }
    if(!table) {
        table = [[UITableView alloc]initWithFrame:CGRectMake(margin,labelNode.fontSize + margin*2,self.size.width-margin*2,self.size.height-margin*4-self.size.width*0.2*0.7-labelNode.fontSize)];
        table.delegate = self;
        table.dataSource = self;
        table.rowHeight = table.frame.size.height/6;
    }
}

-(void)willMoveFromView:(SKView *)view {
    [table removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    [self.view addSubview:table];
    [table reloadData];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"next"]) {
        if(!isPeripheral) {//セントラルならペリフェラルに送信
            //settingCheck:A..A
            [centralManager sendMessageFromClient:[NSString stringWithFormat:@"settingCheck:%@",[BWUtility getIdentificationString]]];
        } else {//ペリフェラルなら内部的に直接値を変更する
            NSString *identificationId = [BWUtility getIdentificationString];
            BOOL isAllOK = YES;
            for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
                if([infoDic[@"players"][i][@"identificationId"] isEqualToString:identificationId]) {
                    checkList[i] = @YES;
                }
                if(![checkList[i]boolValue]) {
                    isAllOK = NO;
                }
            }
            if(isAllOK) {
                //全員確認済み ゲームスタート
                [self gameStart];
            }
        }
        isCheck = YES;
        [self initBackground];
    }
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
    //central
    //gamestart:A..A,S..S,0,0/A..A,S..S,1,0/.../A..A,S..S,8,1
    //セントラル側ではプレイヤー情報を格納しておく（配役とルールはすでに取得済み）
    if([[BWUtility getCommand:message] isEqualToString:@"gamestart"]) {
        NSMutableArray *playerArray = [NSMutableArray array];
        NSArray *components = [BWUtility getCommandContents:message];
        for(NSInteger i=0;i<components.count;i++) {
            NSArray *strings = [components[i] componentsSeparatedByString:@","];
            NSMutableDictionary *dic = [@{@"identificationId":strings[0],@"name":strings[1],@"playerId":@([strings[2]integerValue]),@"roleId":@([strings[3]integerValue]),@"isLive":@YES}mutableCopy];
            [playerArray addObject:dic];
        }
        [infoDic setObject:playerArray forKey:@"players"];
        
        BWRoleRotateScene *scene = [BWRoleRotateScene sceneWithSize:self.size];
        [scene setCentralOrPeripheral:NO :infoDic];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
}

-(void)didReceiveMessage:(NSString *)message {
    //peripheral
    //settingCheck:A..A
    if([[BWUtility getCommand:message] isEqualToString:@"settingCheck"]) {
        NSString *identificationId = [BWUtility getCommandContents:message][0];
        BOOL isAllOK = YES;
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            if([infoDic[@"players"][i][@"identificationId"] isEqualToString:identificationId]) {
                checkList[i] = @YES;
            }
            if(![checkList[i]boolValue]) {
                isAllOK = NO;
            }
        }
        if(isAllOK) {
            //全員確認済み ゲームスタート
            [self gameStart];
        }
    }
}

-(void)gameStart {
    [self setRole];
    
    //先に画面遷移してから通知を送る
    BWRoleRotateScene *scene = [BWRoleRotateScene sceneWithSize:self.size];
    [scene setCentralOrPeripheral:YES :infoDic];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:1.0];
    [self.view presentScene:scene transition:transition];
}

-(void) setRole {
    NSMutableArray *array = infoDic[@"roles"];
    NSMutableArray *rollArray = [NSMutableArray array];
    for(int i=0;i<array.count;i++) {
        int num = [array[i]intValue];
        for(int j=0;j<num;j++) {
            [rollArray addObject:@(i)];
        }
    }
    
    NSMutableArray *shaffleRoleArray = [BWUtility getRandomArray:rollArray];
    
    if([infoDic[@"rules"][@"isLacking"]boolValue]) {
        //役欠け処理
        NSMutableArray *array = [NSMutableArray array];
        for(NSInteger i=0;i<shaffleRoleArray.count;i++) {
            //人狼と妖狐以外のindexを取得
            if([shaffleRoleArray[i]integerValue] != RoleWerewolf && [shaffleRoleArray[i]integerValue] != RoleFox) {
                [array addObject:@(i)];
            }
        }
        [array addObject:@(-1)];//全て役職の時に欠けない処理を行うよう
        
        NSInteger lackIndex = [array[ (int)arc4random_uniform((int)(array.count)) ]integerValue];
        if(lackIndex != -1) {
            NSLog(@"before: index:%d rollId:%@",(int)lackIndex,shaffleRoleArray[lackIndex]);
            Role lackRole = [shaffleRoleArray[lackIndex]integerValue];
            [infoDic setObject:@(lackRole) forKey:@"lackRole"];
            shaffleRoleArray[lackIndex] = @(RoleVillager);//村人に変更
            NSLog(@"after : index:%d rollId:%@",(int)lackIndex,shaffleRoleArray[lackIndex]);
        } else {
            NSLog(@"欠けなし");
        }
    }
    
    for(int i=0;i<[infoDic[@"players"] count];i++) {
        [infoDic[@"players"][i] setObject:shaffleRoleArray[i] forKey:@"roleId"];
        [infoDic[@"players"][i] setObject:@YES forKey:@"isLive"];
        [infoDic[@"players"][i] setObject:@(i) forKey:@"playerId"];
    }
}

@end
