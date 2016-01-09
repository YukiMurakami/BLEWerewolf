//
//  BWNightScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWNightScene.h"
#import "BWUtility.h"
#import "NSObject+BlocksWait.h"

@implementation BWNightScene {
    //リフレッシュ必要変数
    BOOL didAction;
    NSMutableArray *didActionPeripheralArray;
    SKSpriteNode *actionButtonNode;
    NSInteger day;
    
    UITableView *table;
    NSMutableArray *tableArray;
    
    NSInteger targetIndex;
    NSInteger wolfTargetIndex;
    
    UIView *coverView;
    UIView *afternoonView;
    
   
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
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
    
    day = 1;
    
    CGFloat margin = self.size.height*0.02;
    CGFloat statusHeight = 22;
    CGFloat timerHeight = self.size.height*0.1;
    messageViewController = [BWMessageViewController sharedInstance:infoDic];
    messageViewController.view.frame = CGRectMake(margin, margin*2+timerHeight+statusHeight, self.size.width - margin*2, self.size.height - margin*3 - timerHeight - statusHeight);
    messageViewController.delegate = self;
    
    timer = [[BWTimer alloc]init];
    [timer setSeconds:[infoDic[@"rules"][@"nightTimer"]integerValue]*60];
    timer.delegate = self;
    
    CGFloat tableMargin = self.size.height*0.05;
    table = [[UITableView alloc]initWithFrame:CGRectMake(tableMargin, tableMargin + statusHeight, self.size.width-tableMargin*2,self.size.height - (statusHeight+tableMargin*3+self.size.height*0.1))];
    table.rowHeight = table.frame.size.height/6;
    table.delegate = self;
    table.dataSource = self;
    
    didAction = NO;
    didActionPeripheralArray = [NSMutableArray array];
    NSMutableArray *playerArray = infoDic[@"players"];
    for(NSInteger i=0;i<[playerArray count];i++) {
        [didActionPeripheralArray addObject:@(NO)];
    }
    
    [self initBackground];
    
    
    [self nightStart];
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"night.jpg"];
    [self addChild:backgroundNode];
    
    CGFloat margin = self.size.height*0.02;
    CGFloat timerHeight = self.size.height*0.1;
    CGFloat statusHeight = 22;
    
    SKSpriteNode *explain = [[SKSpriteNode alloc]initWithImageNamed:@"frame.png"];
    explain.size = CGSizeMake(timerHeight*218/307,timerHeight);
    explain.position = CGPointMake(-self.size.width/2+explain.size.width/2+margin,self.size.height/2-timerHeight/2-margin-statusHeight);
    SKSpriteNode *content = [[SKSpriteNode alloc]init];
    content.size = CGSizeMake(explain.size.width*0.9,explain.size.height*0.92);
    content.position = CGPointMake(0,0);
    content.texture = [BWUtility getCardTexture:[BWUtility getMyRoleId:infoDic]];
    [explain addChild:content];
    [backgroundNode addChild:explain];
    
    timer.size = CGSizeMake(timerHeight*2.4, timerHeight);
    [timer initNodeWithFontColor:[UIColor whiteColor]];
    timer.position = CGPointMake(explain.position.x + explain.size.width/2 + timer.size.width/2 + margin, explain.position.y);
    [timer removeFromParent];
    [backgroundNode addChild:timer];
    
    
    NSInteger roleId = [BWUtility getMyRoleId:infoDic];
    NSString *buttonTitle = @"";
    NSString *buttonName = @"action";
    
    if(roleId == RoleWerewolf) buttonTitle = @"噛む";
    if(roleId == RoleFortuneTeller) buttonTitle = @"占う";
    CGFloat buttonSizeWidth = self.size.width-(margin*4+explain.size.width+timer.size.width);
    actionButtonNode = [BWUtility makeButton:buttonTitle size:CGSizeMake(buttonSizeWidth,timer.size.height*0.9) name:buttonName position:CGPointMake(self.size.width/2-buttonSizeWidth/2-margin, explain.position.y)];
    if(![buttonTitle isEqualToString:@""] && !didAction) {
        [backgroundNode addChild:actionButtonNode];
    }
    
}

-(void)willMoveFromView:(SKView *)view {
    [messageViewController.view removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    [self.view addSubview:messageViewController.view];
}

-(void)nightStart {
    //リフレッシュ操作を行う
    //GMメッセージを時間差で送信する
    didAction = NO;
    
    NSInteger roleId = [BWUtility getMyRoleId:infoDic];
    if([[BWUtility getCardInfofromId:(int)roleId][@"hasTable"]boolValue]) {
        if(!actionButtonNode.parent) {
            [backgroundNode addChild:actionButtonNode];
        }
    }
    
    if(isPeripheral) {
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            didActionPeripheralArray[i] = @NO;
        }
        
        if(day == 1) {
            [NSObject performBlock:^{
                for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
                    NSInteger roleId = [infoDic[@"players"][i][@"roleId"]integerValue];
                    [NSObject performBlock:^{
                        [self sendGMMessage:[BWUtility getCardInfofromId:(int)roleId][@"firstNightMessage"] receiverId:infoDic[@"players"][i][@"identificationId"]];
                    } afterDelay:0.1*i];
                }
            } afterDelay:3.0];
            [NSObject performBlock:^{
                for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
                    [NSObject performBlock:^{
                        [self sendGMMessage:@"初日の夜になりました。" receiverId:infoDic[@"players"][i][@"identificationId"]];
                    } afterDelay:0.1*i];
                }
            } afterDelay:5.0];
        }
    }
}

-(void)afternoonStart {
    //リフレッシュ操作を行う
    day++;
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"action"]) {
        coverView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
        coverView.backgroundColor = [UIColor blackColor];
        coverView.alpha = 0.8;
        [self.view addSubview:coverView];
        [self setTableData];
        [self.view addSubview:table];
    }
}

-(void)setTableData {
    //TODO::夜のアクションテーブルデータ
    tableArray = [NSMutableArray array];
    NSInteger myRoleId = [BWUtility getMyRoleId:infoDic];
    NSInteger myPlayerId = [BWUtility getMyPlayerId:infoDic];
    NSMutableArray *playerArray = infoDic[@"players"];
    for(NSInteger i=0;i<playerArray.count;i++) {
        NSInteger roleId = [playerArray[i][@"roleId"]integerValue];
        if(myRoleId == RoleWerewolf) {//人狼の場合は仲間の人狼以外の襲撃対象を入れる
            if(roleId != RoleWerewolf) {
                [tableArray addObject:playerArray[i]];
            }
        }
        if(myRoleId == RoleFortuneTeller) {
            if(i != myPlayerId) {
                [tableArray addObject:playerArray[i]];
            }
        }
    }
    
    [table reloadData];
}

-(void)doRoleAction {
    [table removeFromSuperview];
    [coverView removeFromSuperview];
    if(!isPeripheral) {
        //セントラルは命令をペリフェラルに送信
        NSInteger myRoleId = [BWUtility getMyRoleId:infoDic];
        NSString *message = [NSString stringWithFormat:@"action:%d/%d/%d",(int)myRoleId,(int)[BWUtility getMyPlayerId:infoDic],(int)targetIndex];
        [centralManager sendNormalMessage:message interval:5.0 timeOut:15.0 firstWait:0.0];
    } else {
        //ペリフェラルは即実行
        [self processRoleAction:[BWUtility getMyRoleId:infoDic] actionPlayerId:[BWUtility getMyPlayerId:infoDic] targetPlayerId:targetIndex];
    }
    didAction = YES;
    
    [actionButtonNode removeFromParent];
}

-(void)processRoleAction :(NSInteger)roleId actionPlayerId:(NSInteger)actionPlayerId targetPlayerId:(NSInteger)targetPlayerId {
    //TODO::アクション処理箇所
    if([didActionPeripheralArray[actionPlayerId]boolValue]) return;//実行済みのアクションは行わない
    didActionPeripheralArray[actionPlayerId] = @(YES);
    if(roleId == RoleFortuneTeller) {
        NSString *message;
        if([infoDic[@"players"][targetPlayerId][@"roleId"]integerValue] == RoleWerewolf) {
            message = [NSString stringWithFormat:@"占い結果「%@」さんは「人狼 ●」です。",infoDic[@"players"][targetPlayerId][@"name"]];
        } else {
            message = [NSString stringWithFormat:@"占い結果「%@」さんは「人間 ○」です。",infoDic[@"players"][targetPlayerId][@"name"]];
        }
        [self sendGMMessage:message receiverId:infoDic[@"players"][actionPlayerId][@"identificationId"]];
    }
    if(roleId == RoleWerewolf) {
        wolfTargetIndex = targetPlayerId;//噛み先を保存
        //人狼にメッセージを送信
        NSMutableArray *playerArray = infoDic[@"players"];
        NSString *message = [NSString stringWithFormat:@"「%@」さんが「%@」さんを噛みます。",playerArray[actionPlayerId][@"name"],playerArray[targetPlayerId][@"name"]];
        for(NSInteger i=0;i<[playerArray count];i++) {
            if([playerArray[i][@"roleId"]integerValue] == RoleWerewolf) {
                didActionPeripheralArray[i] = @YES;
                [NSObject performBlock:^{
                    [self sendGMMessage:message receiverId:playerArray[i][@"identificationId"]];
                } afterDelay:0.1*i];
            }
        }
    }
}

-(void)sendGMMessage:(NSString*)message receiverId:(NSString*)identificationId {
    if(!isPeripheral) return;
    NSLog(@"GMMessage:%@",message);
    if([identificationId isEqualToString:[BWUtility getIdentificationString]]) {
        //自分自身あて
        [messageViewController receiveMessage:message id:[messageViewController getGmId] infoDic:infoDic];
    } else {
        NSArray *messages = [self divideMessage:message];
        for(NSInteger i=0;i<messages.count;i++) {
            NSString *mes = [NSString stringWithFormat:@"chatreceive:%@/%@/%@",[messageViewController getGmId],identificationId,messages[i]];
            [peripheralManager sendNormalMessage:mes toIdentificationId:identificationId interval:5.0 timeOut:15.0 firstWait:0.1*i];
        }
    }
}

-(NSArray*)getSameChatroomMemberId:(NSString*)identificationId {
    //TODO::送られてきた信号に対して、誰にchat信号を送るべきなのかを振り分ける
    NSMutableArray *shouldSenderId = [NSMutableArray array];
    [shouldSenderId addObject:identificationId];
    
    NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
    NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        NSInteger targetId = [infoDic[@"players"][i][@"roleId"]integerValue];
        //人狼同士
        if(roleId == RoleWerewolf && targetId == RoleWerewolf) {
            [shouldSenderId addObject:@(i)];
        }
    }
    return [shouldSenderId copy];
}

#pragma mark - messageDelegate

-(void)didReceivedMessage:(NSString *)message {
    //central
    //ペリフェラルから受け取ったメッセージから、自分と同じグループチャットがあったら反映
    //ただし自分自信はすでに反映されているのでむし
    //chatreceive:A..A/T...T
    //chatreceive:G..G/A..A/T..T
    if([[BWUtility getCommand:message] isEqualToString:@"chatreceive"]) {
        NSArray *contents = [BWUtility getCommandContents:message];
        if([messageViewController isMember:contents[0]] && ![contents[0] isEqualToString:[BWUtility getIdentificationString]]) {
            //メッセージを反映
            //ただしGMメッセージの場合は振り分ける
            if([[messageViewController getGmId] isEqualToString:contents[0]]) {
                if([[BWUtility getIdentificationString] isEqualToString:contents[1]]) {
                    NSString *text = @"";
                    for(NSInteger i=2;i<contents.count;i++) {
                        text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
                    }
                    [messageViewController receiveMessage:text id:contents[0] infoDic:infoDic];
                }
            } else {
                NSString *text = @"";
                for(NSInteger i=1;i<contents.count;i++) {
                    text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
                }
                [messageViewController receiveMessage:text id:contents[0] infoDic:infoDic];
            }
        }
    }
}

-(void)didReceiveMessage:(NSString *)message {
    //peripheral
    //セントラルから受け取ったメッセージを送るべき相手に送信
    //その後自分と同じグループと同じグループチャットがあったら反映（ただし自分はむし）
    //chatsend:A..A/T...T
    if([[BWUtility getCommand:message] isEqualToString:@"chatsend"]) {
        NSArray *contents = [BWUtility getCommandContents:message];
        NSString *identificationId = contents[0];
        
        NSString *text = @"";
        for(NSInteger i=1;i<contents.count;i++) {
            text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
        }
        
        NSArray *shouldSendIds = [self getSameChatroomMemberId:identificationId];
        for(NSInteger i=0;i<shouldSendIds.count;i++) {
            [peripheralManager sendNormalMessage:[NSString stringWithFormat:@"chatreceive:%@/%@",identificationId,text] toIdentificationId:shouldSendIds[i] interval:5.0 timeOut:15.0 firstWait:0.05*i];
        }
        
        if([messageViewController isMember:identificationId] && ![identificationId isEqualToString:[BWUtility getIdentificationString]]) {
            //メッセージを反映
            NSString *text = @"";
            for(NSInteger i=1;i<contents.count;i++) {
                text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
            }
            [messageViewController receiveMessage:text id:contents[0] infoDic:infoDic];
        }
    }
    
    //action:1/0/3
    if([[BWUtility getCommand:message] isEqualToString:@"action"]) {
        NSArray *contents = [BWUtility getCommandContents:message];
        NSInteger actionRoleId = [contents[0]integerValue];
        NSInteger actionPlayerId = [contents[1]integerValue];
        NSInteger actionTargetId = [contents[2]integerValue];
        
        [self processRoleAction:actionRoleId actionPlayerId:actionPlayerId targetPlayerId:actionTargetId];
    }
}

-(NSArray*)divideMessage :(NSString*)message {
    NSInteger limit = 36;
    NSMutableArray *array = [NSMutableArray array];
   
    while([message length] > limit) {
        [array addObject:[message substringToIndex:limit]];
        message = [message substringFromIndex:limit];
    }
    if(message.length > 0) {
        [array addObject:message];
    }
    return [array copy];
}

#pragma mark - MessageViewControllerdelegate
-(void)didSendChat:(NSString *)message {
    //自分でチャットを送信すると呼ばれる
    //chatsend:A..A/T...T
    //chatreceive:A..A/T...T
    NSArray *array = [self divideMessage:message];
    for(NSInteger j=0;j<array.count;j++) {
        if(isPeripheral) {
            //外部に直接知らせる
            NSString *mes = [NSString stringWithFormat:@"chatreceive:%@/%@",[BWUtility getIdentificationString],array[j]];
            NSArray *shouldSendIds = [self getSameChatroomMemberId:[BWUtility getIdentificationString]];
            for(NSInteger i=0;i<shouldSendIds.count;i++) {
                [peripheralManager sendNormalMessage:mes toIdentificationId:shouldSendIds[i] interval:5.0 timeOut:15.0 firstWait:i*0.05+j*0.1];
            }
        } else {
            //まずはペリフェラルに知らせる
            NSString *mes = [NSString stringWithFormat:@"chatsend:%@/%@",[BWUtility getIdentificationString],array[j]];
            [centralManager sendNormalMessage:mes interval:5.0 timeOut:15.0 firstWait:j*0.1];
        }
    }
}

-(void)update:(NSTimeInterval)currentTime {
    [timer getSeconds];
}

#pragma mark - TimerDelegate
-(void)didDecreaseTime:(NSInteger)seconds {
    
}

#pragma mark - tableDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tableArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    NSString *name = tableArray[indexPath.row][@"name"];
    
    cell.textLabel.text = name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO::テーブルタッチ操作
    NSString *targetIdentificationId = tableArray[indexPath.row][@"identificationId"];
    targetIndex = [BWUtility getPlayerId:infoDic id:targetIdentificationId];
    NSInteger myRoleId = [BWUtility getMyRoleId:infoDic];
    
    NSString *message = @"";
    if(myRoleId == RoleWerewolf) {
        message = [NSString stringWithFormat:@"「%@」さんを噛みますか？",infoDic[@"players"][targetIndex][@"name"]];
    }
    if(myRoleId == RoleFortuneTeller) {
        message = [NSString stringWithFormat:@"「%@」さんを占いますか？",infoDic[@"players"][targetIndex][@"name"]];
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"確認" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"はい" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self doRoleAction];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"いいえ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        ;
    }]];
    [self.view.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
