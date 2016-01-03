//
//  BWRoleRotateScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/02.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWRoleRotateScene.h"
#import "BWUtility.h"

@implementation BWRoleRotateScene {
    BOOL isFinishLoopTimer;
    BOOL isCheck;
    NSMutableArray *checkList;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    return self;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic {
    isPeripheral = _isPeripheral;
    
    infoDic = _infoDic;
    
    isCheck = NO;
    
    tablePlayerArray = [NSMutableArray array];
    
    if(isPeripheral) {
        checkList = [NSMutableArray array];
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            [checkList addObject:@NO];
        }
        
        peripheralManager = [BWPeripheralManager sharedInstance];
        peripheralManager.delegate = self;
        
        //全員に役職とプレイヤー情報を送信する
        //受信確認は役職確認後に受信通知を返してもらう
        //gamestart:A..A,S..S,0,0/A..A,S..S,1,0/.../A..A,S..S,8,1
        isFinishLoopTimer = NO;
        NSString *message = @"gamestart:";
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            NSMutableDictionary *playerInfo = infoDic[@"players"][i];
            message = [NSString stringWithFormat:@"%@%@,%@,%@,%@",message,playerInfo[@"identificationId"],playerInfo[@"name"],playerInfo[@"playerId"],playerInfo[@"roleId"]];
            if(i != [infoDic[@"players"] count]-1) {
                message = [NSString stringWithFormat:@"%@/",message];
            }
        }
        [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(sendMessage:) userInfo:@{@"message":message} repeats:YES];
    } else {
        centralManager = [BWCentralManager sharedInstance];
        centralManager.delegate = self;
    }
    
    [self initBackground];
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"night.jpg"];
    [self addChild:backgroundNode];
    
    [self rotateRoleCard];
}

-(void)initNextBackground {
    NSArray *nodes = backgroundNode.children;
    for(int i=0;i<nodes.count;i++) {
        SKNode *node = nodes[i];
        [node removeFromParent];
    }
    
    NSInteger playerId = [BWUtility getMyPlayerId:infoDic];
    NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
    NSMutableDictionary *roleDic = [BWUtility getCardInfofromId:(int)roleId];
    NSInteger surfaceRoleId = [roleDic[@"surfaceRole"]integerValue];

    SKTexture *texture = [BWUtility getCardTexture:surfaceRoleId];
    NSString *string = [NSString stringWithFormat:@"あなたの役職は「%@」です。%@",roleDic[@"name"],roleDic[@"explain"]];
    CGSize messageSize = CGSizeMake(self.size.width*0.9, self.size.width*0.9/300*240);
    CGPoint messagePosition = CGPointMake(0, self.size.height/2 - 22 - messageSize.height/2);
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    CGFloat margin = buttonSize.height/2;
    UIColor *fontColor = [UIColor whiteColor];
    CGFloat fontSize = messageSize.height/15;
        
    
    if(roleId == RoleBodyguard) {
        if([infoDic[@"rules"][@"canContinuousGuard"]boolValue]) {
            string = [NSString stringWithFormat:@"%@連続ガード「あり」です。",string];
        } else {
            string = [NSString stringWithFormat:@"%@連続ガード「なし」です。",string];
        }
    }
        
    SKSpriteNode *messageNode = [BWUtility makeMessageAndImageNode:messageSize
                                                          position:messagePosition
                                                             color:[UIColor blackColor]
                                                            string:string
                                                          fontSize:fontSize
                                                         fontColor:fontColor
                                                      imageTexture:texture
                                                    imageWidthRate:0.2
                                                     isRotateRight:NO];
    [backgroundNode addChild:messageNode];
        
    if(![[BWUtility getCardInfofromId:roleId][@"hasTableFirst"]boolValue]) {
        NSString *actionString = @"特に行うアクションはありません。「初日夜へ」を押してください。";
        SKSpriteNode *notActionNode = [BWUtility makeMessageNode:CGSizeMake(self.size.width/8*5, self.size.width/8*2) position:CGPointMake(0,-self.size.height/2+margin*3+buttonSize.height/2*3) backColor:[UIColor blackColor] string:actionString fontSize:14 fontColor:[UIColor whiteColor]];
        [backgroundNode addChild:notActionNode];
        
        
        SKSpriteNode *button = [BWUtility makeButton:@"初日夜へ" size:buttonSize name:@"start" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
        if(!isCheck) {
            [backgroundNode addChild:button];
        } else {
            SKLabelNode *checkedLabelNode = [[SKLabelNode alloc]init];
            checkedLabelNode.text = @"全員の確認待ち";
            checkedLabelNode.fontColor = [UIColor blackColor];
            checkedLabelNode.fontSize = self.size.width*0.2*0.7*0.7;
            checkedLabelNode.position = CGPointMake(0, -self.size.height/2+margin+buttonSize.height/2);
            [backgroundNode addChild:checkedLabelNode];
        }
        return;
    } else {
        [self setTableDataFirst:roleId playerId:playerId];
        
        SKSpriteNode *button = [BWUtility makeButton:@"初日夜へ" size:buttonSize name:@"start" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
        if(!isCheck) {
            [backgroundNode addChild:button];
        } else {
            SKLabelNode *checkedLabelNode = [[SKLabelNode alloc]init];
            checkedLabelNode.text = @"全員の確認待ち";
            checkedLabelNode.fontColor = [UIColor blackColor];
            checkedLabelNode.fontSize = self.size.width*0.2*0.7*0.7;
            checkedLabelNode.position = CGPointMake(0, -self.size.height/2+margin+buttonSize.height/2);
            [backgroundNode addChild:checkedLabelNode];
        }
        
        if(!table) {
            table = [[UITableView alloc]initWithFrame:CGRectMake(self.size.width*0.05,self.size.height/2 - messagePosition.y + messageSize.height/2 + margin*0.5 ,self.size.width*0.9,self.size.height - (22+messageSize.height+margin*2+button.size.height))];
            table.delegate = self;
            table.dataSource = self;
            table.rowHeight = table.frame.size.height*0.3;
            [self.view addSubview:table];
        }
        [table reloadData];
    }
}

-(void) setTableDataFirst :(NSInteger)roleId playerId:(NSInteger)playerId{
    //TODO::初夜のテーブル編集
    [tablePlayerArray removeAllObjects];
    NSMutableArray *playerArray = infoDic[@"players"];
    for(int i=0;i<playerArray.count;i++) {
        NSMutableDictionary *player = playerArray[i];
        
        int playersRoleId = [player[@"roleId"]intValue];
        
        if(roleId == RoleWerewolf) {
            if((playersRoleId == RoleWerewolf) && playerId != i) {//人狼仲間確認
                [tablePlayerArray addObject:player];
            }
        }
        if(roleId == RoleFox) {//妖狐は妖狐を確認
            if(playersRoleId == RoleFox && playerId != i) {
                [tablePlayerArray addObject:player];
            }
        }
        if(roleId == RoleJointOwner) {
            if(playersRoleId == RoleJointOwner && playerId != i) {//共有者仲間を確認
                [tablePlayerArray addObject:player];
            }
        }
    }
}

-(void)rotateRoleCard {
    NSInteger playerId = [BWUtility getMyPlayerId:infoDic];
    
    NSMutableArray *textures = [NSMutableArray array];
    //TODO::絵が出来上がったら増やす
    for(int i=0;i<[BWUtility getMaxRoleCount];i++) {
        SKTexture *texture = [BWUtility getCardTexture:i];
        [textures addObject:texture];
    }
    
    SKTexture *backCardTexture = [SKTexture textureWithImageNamed:@"back_card.jpg"];
    SKAction *wait = [SKAction waitForDuration:1.0];
    SKAction *anime = [SKAction animateWithTextures:textures timePerFrame:0.02f];
    SKAction *animes = [SKAction sequence:@[wait,[SKAction repeatAction:anime count:10]]];
    
    SKSpriteNode *explain = [[SKSpriteNode alloc]initWithImageNamed:@"frame.png"];
    explain.size = CGSizeMake(self.size.width*0.65,self.size.width*0.65/218*307);
    explain.position = CGPointMake(0,0);
    SKSpriteNode *content = [[SKSpriteNode alloc]init];
    content.size = CGSizeMake(explain.size.width*0.9,explain.size.height*0.92);
    content.position = CGPointMake(0,0);
    content.texture = backCardTexture;
    
    [content runAction:animes completion:^{
        NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
        NSInteger surfaceRoleId = [[BWUtility getCardInfofromId:(int)roleId][@"surfaceRole"] integerValue];
        content.texture = [BWUtility getCardTexture:(int)surfaceRoleId];
        NSLog(@"役職:%@",[BWUtility getCardInfofromId:roleId][@"name"]);
        CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
      
        SKSpriteNode *button = [BWUtility makeButton:@"詳細確認" size:buttonSize name:@"next" position:CGPointMake(0, -explain.size.height/2 - (self.size.height - explain.size.height)/4)];
        [backgroundNode addChild:button];
    }];
    
    [explain addChild:content];
    [backgroundNode addChild:explain];
}

-(void)sendMessage:(NSTimer*)timer {
    if(isFinishLoopTimer) {
        [timer invalidate];
        return ;
    }
    [[BWPeripheralManager sharedInstance] updateSendMessage:[timer userInfo][@"message"]];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"next"]) {
        [self initNextBackground];
    }
        
    if([node.name isEqualToString:@"start"]) {
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
                //全員確認済み 初日よるへ
                [self goFirstNight];
            }
        }
        isCheck = YES;
        [self initNextBackground];
    }
}

-(void)goFirstNight {
    
}

-(void)didReceivedMessage:(NSString *)message {
    //central
}

-(void)didReceiveMessage:(NSString *)message {
    //peripheral
    //roleCheck:A..A
    if([[BWUtility getCommand:message] isEqualToString:@"roleCheck"]) {
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
            //全員確認済み 初日よるへ
            [self goFirstNight];
        }
    }
}

#pragma mark - tableDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tablePlayerArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
        
    NSDictionary *playerInfo = tablePlayerArray[indexPath.row];
    
    NSString *name = playerInfo[@"name"];
    
    //NSInteger playerId = [BWUtility getMyPlayerId:infoDic];
    //NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
    
    cell.textLabel.text = name;
    
    return cell;
}

// ヘッダー配置
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // ヘッダー画像配置
    UILabel *label = [[UILabel alloc]init];
    
    NSInteger playerId = [BWUtility getMyPlayerId:infoDic];
    NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
    
    NSString *string = [BWUtility getCardInfofromId:roleId][@"tableStringFirst"];
    
    label.textColor = [UIColor blackColor];
    label.text = string;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    return label;
}

// ヘッダーの高さ指定
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

@end
