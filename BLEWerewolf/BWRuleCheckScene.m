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
#import "BWGorgeousTableView.h"

@implementation BWRuleCheckScene {
    BOOL isCheck;
    NSMutableArray *checkList;
    
    BWGorgeousTableView *table;
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

    CGFloat margin = self.size.width * 0.1;
    
    SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width-margin*2, (self.size.width-margin*2)/4) title:@"ルール確認"];
    titleNode.position = CGPointMake(0, self.size.height/2 - titleNode.size.height/2 - margin);
    [backgroundNode addChild:titleNode];
    
    CGSize size = CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2);
    
    if(!isCheck) {
        BWButtonNode *buttonNode = [[BWButtonNode alloc]init];
        [buttonNode makeButtonWithSize:size name:@"next" title:@"確認" boldRate:1.0];
        buttonNode.delegate = self;
        [backgroundNode addChild:buttonNode];
        buttonNode.position = CGPointMake(0, -self.size.height/2 + margin + buttonNode.size.height/2);
    } else {
        SKLabelNode *checkedLabelNode = [[SKLabelNode alloc]init];
        checkedLabelNode.text = @"全員の確認待ち";
        checkedLabelNode.fontColor = [UIColor blackColor];
        checkedLabelNode.fontSize = size.height*0.7;
        checkedLabelNode.position = CGPointMake(0, -self.size.height/2+margin+size.height/2);
        [backgroundNode addChild:checkedLabelNode];
    }
    if(!table) {
        table = [[BWGorgeousTableView alloc]initWithFrame:CGRectMake(margin,titleNode.size.height + margin*2,self.size.width-margin*2,self.size.height-margin*4-size.height-titleNode.size.height)];
        [table setViewDesign:self];
        table.tableView.rowHeight = table.tableView.frame.size.height/6;
        table.tableView.allowsSelection = NO;
        table.tableView.scrollEnabled = NO;
    }
}

-(void)willMoveFromView:(SKView *)view {
    [table removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    [self.view addSubview:table];
    [table.tableView reloadData];
    
    if(isPeripheral) {
        //setting:/6,3,1,1,1,1/7,3,0,1,1
        NSMutableDictionary *ruleDic = infoDic[@"rules"];
        NSMutableArray *roleArray = infoDic[@"roles"];
        NSString *ruleString = @"setting:";
        for(NSInteger i=0;i<[BWUtility getMaxRoleCount];i++) {
            if(i != [BWUtility getMaxRoleCount]-1) {
                ruleString = [NSString stringWithFormat:@"%@%@,",ruleString,roleArray[i]];
            } else {
                ruleString = [NSString stringWithFormat:@"%@%@/",ruleString,roleArray[i]];
            }
        }
        
        ruleString = [NSString stringWithFormat:@"%@%@,",ruleString,ruleDic[@"timer"]];
        ruleString = [NSString stringWithFormat:@"%@%@,",ruleString,ruleDic[@"nightTimer"]];
        ruleString = [NSString stringWithFormat:@"%@%@,",ruleString,ruleDic[@"fortuneMode"]];
        ruleString = [NSString stringWithFormat:@"%@%@,",ruleString,ruleDic[@"canContinuousGuard"]];
        ruleString = [NSString stringWithFormat:@"%@%@",ruleString,ruleDic[@"isLacking"]];
        
        [peripheralManager sendNormalMessageEveryClient:ruleString infoDic:infoDic interval:5.0 timeOut:30.0];
    }
}

-(void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"next"]) {
        if(!isPeripheral) {//セントラルならペリフェラルに送信
            //settingCheck:A..A
            [centralManager sendNormalMessage:[NSString stringWithFormat:@"settingCheck:%@",[BWUtility getIdentificationString]] interval:5.0 timeOut:15.0 firstWait:0.0];
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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
}

#pragma mark - tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + [[infoDic[@"rules"] allKeys] count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:0];
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    NSString *title = @"";
    NSString *detailTitle = @"";
    if(indexPath.row == 0) {
        title = @"配役";
        detailTitle = [BWUtility getRoleSetString:infoDic[@"roles"]];
    }
    if(indexPath.row == 1) {
        title = @"昼時間";
        detailTitle = [NSString stringWithFormat:@"%@分",infoDic[@"rules"][@"timer"]];
    }
    if(indexPath.row == 2) {
        title = @"夜時間";
        detailTitle = [NSString stringWithFormat:@"%@分",infoDic[@"rules"][@"nightTimer"]];
    }
    if(indexPath.row == 3) {
        title = @"初日占い";
        detailTitle = [[BWUtility getFortuneButtonString:[infoDic[@"rules"][@"fortuneMode"]integerValue]] substringFromIndex:5];
    }
    if(indexPath.row == 4) {
        title = @"連続護衛";
        BOOL canGuard = [infoDic[@"rules"][@"canContinuousGuard"]boolValue];
        if(canGuard) {
            detailTitle = @"あり";
        } else {
            detailTitle = @"なし";
        }
    }
    if(indexPath.row == 5) {
        title = @"役かけ";
        BOOL isLack = [infoDic[@"rules"][@"isLacking"]boolValue];
        if(isLack) {
            detailTitle = @"あり";
        } else {
            detailTitle = @"なし";
        }
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@   %@",title,detailTitle];
    
    return cell;
}

-(void)didReceivedMessage:(NSString *)message {
    //central
    //gamestart:0,0/1,0/.../8,1
    //セントラル側では役職IDを格納しておく（配役とルールとプレイヤーはすでに取得済み）
    if([[BWUtility getCommand:message] isEqualToString:@"gamestart"]) {
        NSArray *components = [BWUtility getCommandContents:message];
        for(NSInteger i=0;i<components.count;i++) {
            NSArray *strings = [components[i] componentsSeparatedByString:@","];
            [infoDic[@"players"][[strings[0]integerValue]] setObject:@([strings[1]integerValue]) forKey:@"roleId"];
            [infoDic[@"players"][[strings[0]integerValue]] setObject:@YES forKey:@"isLive"];
        }
        
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
    
    //先に画面遷移してから通知を送る（こっち側では一回だけ送っとく）
    
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
