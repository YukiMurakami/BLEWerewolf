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
#import "BWTopScene.h"

#import "BWAppDelegate.h"
#import "BWViewController.h"

typedef NS_ENUM(NSInteger,Phase) {
    PhaseNight,
    PhaseNightFinish,
    PhaseAfternoon,
    PhaseAfternoonFinish,
    PhaseVotingFinish,
};

@implementation BWNightScene {
    //リフレッシュ必要変数
    BOOL didAction;
    NSMutableArray *didActionPeripheralArray;
    SKSpriteNode *actionButtonNode;
    SKSpriteNode *explain;//役職カード
    NSInteger day;
    Phase phase;
    NSMutableArray *checkList;//全員の夜終了を確認する
    //この辺のゲーム進行用変数は基本的にペリフェラルのみ
    NSInteger targetIndex;
    NSInteger wolfTargetIndex;
    NSInteger voteCount;
    NSMutableArray *victimArray;//これは情報をセントラルでも共有する
    NSMutableArray *bodyguardArray;
    NSMutableArray *votingArray;//投票履歴1日分 (リフレッシュ時にinfoDic[@"voting"]に書き込んでいく)
    
    
    SKSpriteNode *checkButton;//投票確認用ぼたんなど
    SKLabelNode *waitLabelNode;//かくにん待ち表示用
    SKSpriteNode *voteCheckNode;
    
    NSInteger excutionerId;
    
    UITableView *table;
    NSMutableArray *tableArray;
    NSString *tableHeaderString;
    NSInteger tableRoleId;
    
    
    UIView *coverView;
    UIView *afternoonView;
    
    SKView *deadPeripheralCoverView;
    
    Winner winner;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    return self;
}

-(void)resetCheckList {//ペリフェラルのみ
    checkList = [NSMutableArray array];
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        [checkList addObject:@NO];
    }
}

-(void)resetDidActionPeripheralArray {//ペリフェラルのみ
    didActionPeripheralArray = [NSMutableArray array];
    NSMutableArray *playerArray = infoDic[@"players"];
    for(NSInteger i=0;i<[playerArray count];i++) {
        [didActionPeripheralArray addObject:@(NO)];
    }
}

-(BOOL)isAllOkCheckList {//ペリフェラルのみ (チェックは生存者のみとする)
    BOOL isAllOk = YES;
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        if([infoDic[@"players"][i][@"isLive"]boolValue] && ![checkList[i]boolValue]) {
            isAllOk = NO;
            break;
        }
    }
    return isAllOk;
}

-(BOOL)isAllVoting {//ペリフェラルのみ（チェックは生存者のみ）
    BOOL isAllOk = YES;
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        if([infoDic[@"players"][i][@"isLive"]boolValue] && ![didActionPeripheralArray[i]boolValue]) {
            isAllOk = NO;
            break;
        }
    }
    return isAllOk;
}

-(Winner)checkWinner {//ペリフェラルのみ　勝利条件を確認（夜突入と朝突入時）
    NSInteger nWerewolf = 0;
    NSInteger nHuman = 0;
    NSInteger nFox = 0;
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        if(![infoDic[@"players"][i][@"isLive"]boolValue]) continue;
        //生存者を確認
        NSInteger roleId = [infoDic[@"players"][i][@"roleId"]integerValue];
        if(roleId == RoleWerewolf) {
            nWerewolf++;
        } else if(roleId == RoleFox) {
            nFox++;
        } else {
            nHuman++;
        }
    }
    if(nWerewolf <= 0) {
        if(nFox <= 0) {
            return WinnerVillager;
        } else {
            return WinnerFox;
        }
    } else {
        if(nWerewolf >= nHuman) {
            return WinnerWerewolf;
        }
    }
    return WinnerNone;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic {//共通　情報をリレーする
    isPeripheral = _isPeripheral;
    
    infoDic = _infoDic;
    
    winner = WinnerNone;
    
    if(isPeripheral) {
        peripheralManager = [BWPeripheralManager sharedInstance];
        peripheralManager.delegate = self;
        [self resetCheckList];
        voteCount = 1;
    } else {
        centralManager = [BWCentralManager sharedInstance];
        centralManager.delegate = self;
    }
    
    day = 1;
    excutionerId = -1;
    phase = PhaseNight;
    
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
    [self resetDidActionPeripheralArray];
    
    [self initBackground];
    
    
    [self nightStart];
}

-(void)initBackground {//共通　背景の描画
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"night.jpg"];
    [self addChild:backgroundNode];
    
    CGFloat margin = self.size.height*0.02;
    CGFloat timerHeight = self.size.height*0.1;
    CGFloat statusHeight = 22;
    
    explain = [[SKSpriteNode alloc]initWithImageNamed:@"frame.png"];
    explain.size = CGSizeMake(timerHeight*5/6,timerHeight);
    explain.position = CGPointMake(-self.size.width/2+explain.size.width/2+margin,self.size.height/2-timerHeight/2-margin-statusHeight);
    explain.texture = [BWUtility getCardTexture:[BWUtility getMyRoleId:infoDic]];
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
    if(roleId == RoleFortuneTeller) buttonTitle = @"守る";
    
    CGFloat buttonSizeWidth = self.size.width-(margin*4+explain.size.width+timer.size.width);
    actionButtonNode = [BWUtility makeButton:buttonTitle size:CGSizeMake(buttonSizeWidth,timer.size.height*0.9) name:buttonName position:CGPointMake(self.size.width/2-buttonSizeWidth/2-margin, explain.position.y)];
    if(![buttonTitle isEqualToString:@""] && !didAction) {
        if(!((roleId == RoleWerewolf || roleId == RoleBodyguard) && day == 1)) {//人狼の初日襲撃はなし
            [backgroundNode addChild:actionButtonNode];
        }
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
    phase = PhaseNight;
    victimArray = [NSMutableArray array];
    if(isPeripheral) {
        bodyguardArray = [NSMutableArray array];
        wolfTargetIndex = -1;
    }
    didAction = NO;
    if(isPeripheral) {
        [self resetDidActionPeripheralArray];
    }
    [self backgroundMorphing:[SKTexture textureWithImageNamed:@"night.jpg"] time:1.0];
    NSInteger roleId = [BWUtility getMyRoleId:infoDic];
    if([[BWUtility getCardInfofromId:(int)roleId][@"hasTable"]boolValue]) {
        if(!actionButtonNode.parent) {
            if(!((roleId == RoleWerewolf || roleId == RoleBodyguard) && day == 1)) {//人狼の初日襲撃はなし
                [backgroundNode addChild:actionButtonNode];
            }
        }
    }
    explain.texture = [BWUtility getCardTexture:roleId];
    
    if(day >= 2) {
        [voteCheckNode removeFromParent];
        messageViewController.view.hidden = NO;
        [waitLabelNode removeFromParent];
        [timer setSeconds:[infoDic[@"rules"][@"nightTimer"]integerValue]*60];
        
        if([[BWUtility getCardInfofromId:[BWUtility getMyRoleId:infoDic]][@"hasTable"]boolValue] && !didAction) {
            actionButtonNode.hidden = NO;
        }
        
        //TODO::ここで生存判定を書き換える（処刑による死亡）
        if(excutionerId != -1) {
            infoDic[@"players"][excutionerId][@"isLive"] = @NO;
            if([BWUtility getMyPlayerId:infoDic] == excutionerId) {
                [self dead:YES];
                if(!isPeripheral) {
                    return;
                }
            }
        }
    }
    
    //GMメッセージを時間差で送信する
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
        if(day != 1) {
            [NSObject performBlock:^{
                for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
                    
                    if([infoDic[@"players"][i][@"roleId"]integerValue] == RoleShaman) {
                        //TODO::霊媒メッセージ送信
                        [NSObject performBlock:^{
                            NSInteger excutionerRoleId = [infoDic[@"players"][excutionerId][@"roleId"]integerValue];
                            NSString *result = @"「人間 ○」";
                            if(excutionerRoleId == RoleWerewolf) {
                                result = @"「人狼 ●」";
                            }
                            NSString *mes = [NSString stringWithFormat:@"霊媒結果「%@」さんは%@でした",infoDic[@"players"][excutionerId][@"name"],result];
                            [self sendGMMessage:mes receiverId:infoDic[@"players"][i][@"identificationId"]];
                        } afterDelay:2.0];
                    }
                    
                    [NSObject performBlock:^{
                        [self sendGMMessage:[NSString stringWithFormat:@"%d日目の夜になりました。",day] receiverId:infoDic[@"players"][i][@"identificationId"]];
                    } afterDelay:0.1*i];
                }
            } afterDelay:5.0];
            
            //TODO::勝利条件チェック
            if([self checkWinner] != WinnerNone) {
                //ゲームセット
                //ゲーム終了を通知「gameEnd:W」
                winner = [self checkWinner];
                NSString *mes = [NSString stringWithFormat:@"gameEnd:%d",(int)winner];
                [peripheralManager sendNormalMessageEveryClient:mes infoDic:infoDic interval:3.0 timeOut:60.0];
                [self gameEnd];
                return;
            }
            
            //２日目以降は夜開始を通知「nightStart:」
            [peripheralManager sendNormalMessageEveryClient:@"nightStart:" infoDic:infoDic interval:3.0 timeOut:30.0];
            [self resetCheckList];
        }
    }
}

-(void)afternoonStart {
    phase = PhaseAfternoon;
    if(isPeripheral) {
        [self resetCheckList];
        
        [self resetDidActionPeripheralArray];
        
        //TODO::朝の犠牲者処理 きつねとかは占いアクション中に処理してしまう
        if(wolfTargetIndex == -1 && day != 1) {
            //ランダムに襲撃先を決める
            NSMutableArray *candidates = [NSMutableArray array];
            //生存者で人狼以外が候補
            for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
                if(![infoDic[@"players"][i][@"isLive"]boolValue]) continue;
                if([infoDic[@"players"][i][@"roleId"]integerValue] == RoleWerewolf) continue;
                [candidates addObject:@(i)];
            }
            wolfTargetIndex = [candidates[[BWUtility getRandInteger:candidates.count]]integerValue];
        }
        if(wolfTargetIndex != -1 && ![bodyguardArray containsObject:@(wolfTargetIndex)]) {
            //護衛失敗の場合は死亡
            [victimArray addObject:@(wolfTargetIndex)];
        }
    }
    
    //TODO::ここで生存判定を書き換える（夜間死亡者）
    for(NSInteger i=0;i<victimArray.count;i++) {
        infoDic[@"players"][[victimArray[i]integerValue]][@"isLive"] = @NO;
        if([BWUtility getMyPlayerId:infoDic] == [victimArray[i]integerValue]) {
            [self dead:NO];
            if(!isPeripheral) {
                return;
            }
        }
    }
    
    if(isPeripheral) {
        //ペリフェラルはセントラルに朝開始と犠牲者を通知
        //TODO::勝利判定を行い、ゲーム終了の場合は終了通知を送る
        if([self checkWinner] != WinnerNone) {
            //ゲームセット
            //ゲーム終了を通知「gameEnd:W」
            winner = [self checkWinner];
            NSString *mes = [NSString stringWithFormat:@"gameEnd:%d",(int)winner];
            [peripheralManager sendNormalMessageEveryClient:mes infoDic:infoDic interval:3.0 timeOut:60.0];
            [self gameEnd];
            return;
        }
        
        //朝開始＋犠牲者通知「afternoonStart:2,4」数値は犠牲者のプレイヤーID
        NSString *mes = [NSString stringWithFormat:@"afternoonStart:%@",[victimArray componentsJoinedByString:@","]];
        [peripheralManager sendNormalMessageEveryClient:mes infoDic:infoDic interval:3.0 timeOut:30.0];
    }
    

    
    //リフレッシュ操作を行う
    day++;
    excutionerId = -1;
    
    //backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    [self backgroundMorphing:[SKTexture textureWithImageNamed:@"afternoon.jpg"] time:1.0];
    explain.texture = [SKTexture textureWithImageNamed:@"back_card.jpg"];
    [timer setSeconds:[infoDic[@"rules"][@"timer"]integerValue]*60];
    votingArray = [NSMutableArray array];
}


-(void)backgroundMorphing :(SKTexture*)nextTexture time:(double)time {
    SKSpriteNode *old = [[SKSpriteNode alloc]initWithTexture:backgroundNode.texture];
    backgroundNode.texture = nextTexture;
    old.size = backgroundNode.size;
    [backgroundNode addChild:old];
    old.zPosition = 0.0;
    SKAction *fadeOut = [SKAction sequence:@[[SKAction fadeAlphaTo:0.0 duration:time],[SKAction removeFromParent]]];
    [old runAction:fadeOut];
}


-(void)finishNight {
    //夜終了
    phase = PhaseNightFinish;
    messageViewController.view.hidden = YES;
    table.hidden = YES;
    [coverView removeFromSuperview];
    [messageViewController eraseKeyboard];
    if(actionButtonNode.parent) {
        [actionButtonNode removeFromParent];
    }
    
    
    [self backgroundMorphing:[SKTexture textureWithImageNamed:@"morning.jpg"] time:1.0];
    //backgroundNode.texture = [SKTexture textureWithImageNamed:@"morning.jpg"];
    
    if(isPeripheral) {
        //ペリフェラルは直接夜時間終了処理を行う
        NSInteger myPlayerId = [BWUtility getMyPlayerId:infoDic];
        checkList[myPlayerId] = @YES;
        if([self isAllOkCheckList]) {
            [self afternoonStart];
        }
    } else {
        //セントラルは夜時間終了を通知「nightFinish:A..A」
        [centralManager sendNormalMessage:[NSString stringWithFormat:@"nightFinish:%@",[BWUtility getIdentificationString]] interval:5.0 timeOut:15.0 firstWait:0.0];
        //ペリフェラルからの朝通知を待つ
    }
}

-(void)finishAfternoon {
    //昼終了
    didAction = NO;
    phase = PhaseAfternoonFinish;
    //全員処刑投票用のテーブルを表示する
    [self setTableData:-1];
    if(!table.superview) {
        [self.view addSubview:table];
    }
    table.hidden = NO;
}

-(void)finishVoting {
    //投票終了　投票結果確認フェーズ
    phase = PhaseVotingFinish;
    if(isPeripheral) {
        [self resetDidActionPeripheralArray];
        [self resetCheckList];
        //TODO::処刑による犠牲者処理
        
        //ペリフェラルはセントラルに処刑者と投票結果を通知
        //投票結果通知「voteResult:1/-1/0,0,1/1,5,2/2,8,0/.../8,1,1」何回目の投票か、最多得票者、投票内訳(投票者、投票先、投票者に何票はいったか)の順番（最多得票者が-1の場合は決戦orランダム、生存者分のみ)
       
        //集計
        NSMutableArray *counter = [NSMutableArray array];
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            [counter addObject:@(0)];
        }
        for(NSInteger i=0;i<votingArray.count;i++) {
            NSInteger votederId = [votingArray[i][@"voteder"]integerValue];
            counter[votederId] = @([counter[votederId]integerValue]+1);
        }
        NSMutableArray *maxIndices = [NSMutableArray array];
        NSInteger maxCount = 0;
        for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
            NSInteger count = [counter[i]integerValue];
            if(maxCount < count) {
                [maxIndices removeAllObjects];
                [maxIndices addObject:@(i)];
                maxCount = count;
            } else if(maxCount == count) {
                [maxIndices addObject:@(i)];
            }
        }
        for(NSInteger i=0;i<votingArray.count;i++) {//ここで辞書に集計結果を保存
            NSInteger voterId = [votingArray[i][@"voter"]integerValue];
            [votingArray[i] setObject:@([counter[voterId]integerValue]) forKey:@"count"];
        }
        
        //TODO::決選投票について（今はランダムに選ぶ）
        excutionerId = [maxIndices[[BWUtility getRandInteger:maxIndices.count]]integerValue];
        NSString *message = [NSString stringWithFormat:@"voteResult:%d/%d",(int)voteCount,(int)excutionerId];
        for(NSInteger i=0;i<votingArray.count;i++) {
            NSInteger votederId = [votingArray[i][@"voteder"]integerValue];
            NSInteger voterId = [votingArray[i][@"voter"]integerValue];
            NSInteger count = [counter[voterId]integerValue];
            message = [NSString stringWithFormat:@"%@/%d,%d,%d",message,(int)voterId,(int)votederId,(int)count];
        }
        [peripheralManager sendNormalMessageEveryClient:message infoDic:infoDic interval:5.0 timeOut:30.0];
    }
    
    
    //投票結果表示　＋　確認ボタン表示 + 投票結果の保存
    voteCheckNode = [BWUtility makeVoteResultNode:CGSizeMake(self.size.width*0.8, self.size.height*0.8) position:CGPointMake(0, 0) texture:[SKTexture textureWithImageNamed:@"frame.png"] day:day voteCount:voteCount excutionerId:excutionerId voteArray:votingArray infoDic:infoDic];
    [backgroundNode addChild:voteCheckNode];
    
    CGFloat margin = self.size.height*0.05;
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    checkButton = [BWUtility makeButton:@"確認" size:buttonSize name:@"check" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
    [backgroundNode addChild:checkButton];
}

-(void)gameEnd {
    
    if(isPeripheral) {
        [deadPeripheralCoverView removeFromSuperview];
    }
    
    [backgroundNode removeAllChildren];
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    table.hidden = YES;
    [messageViewController eraseKeyboard];
    messageViewController.view.hidden = YES;
    
    CGSize size = CGSizeMake(self.size.width*0.6, self.size.width*0.6*0.8);
    NSString *mes = @"";
    if(winner == WinnerVillager) {
        mes = @"村に潜んだすべての人狼を追放しました。村人チームの勝利です。";
    }
    if(winner == WinnerWerewolf) {
        mes = @"人狼達は最後の獲物を捕らえた後、次の村へと去って行きました。人狼チームの勝利です。";
    }
    if(winner == WinnerFox) {
        mes = @"妖狐は村人と人狼を欺き、この村を支配しました。妖狐チームの勝利です。";
    }
    SKSpriteNode *messageNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:mes fontSize:size.height*0.11];
    messageNode.position = CGPointMake(0, 0);
    [backgroundNode addChild:messageNode];
    
    CGFloat margin = self.size.height*0.05;
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    checkButton = [BWUtility makeButton:@"終了する" size:buttonSize name:@"end" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
    [backgroundNode addChild:checkButton];
}

-(void)dead:(BOOL)isExcute {
    
    if(isPeripheral) {
        //ペリフェラルは死亡後も信号のやり取りを行う必要がある
        deadPeripheralCoverView = [[SKView alloc]initWithFrame:self.view.frame];
        SKScene *coverScene = [[SKScene alloc]initWithSize:self.size];
        [self.view addSubview:deadPeripheralCoverView];
        [deadPeripheralCoverView presentScene:coverScene];
        
        SKSpriteNode *coverBackgroundNode = [[SKSpriteNode alloc]init];
        coverBackgroundNode.size = coverScene.size;
        coverBackgroundNode.position = CGPointMake(coverScene.size.width/2, coverScene.size.height/2);
        coverBackgroundNode.texture = [SKTexture textureWithImageNamed:@"heven.jpg"];
        [coverScene addChild:coverBackgroundNode];

        
        CGSize size = CGSizeMake(self.size.width*0.6, self.size.width*0.6*0.8);
        NSString *mes = @"あなたは襲撃されました。";
        if(isExcute) mes = @"あなたは処刑されました。";
        SKSpriteNode *messageNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:[NSString stringWithFormat:@"%@以後ゲームが終了するまで話をすることができません。",mes] fontSize:size.height*0.11];
        messageNode.position = CGPointMake(0, 0);
        [coverBackgroundNode addChild:messageNode];
        
        SKSpriteNode *heven = [[SKSpriteNode alloc]init];
        heven.texture = [SKTexture textureWithImageNamed:@"heven.jpg"];
        heven.size = coverBackgroundNode.size;
        [coverBackgroundNode addChild:heven];
        SKAction *fadeOut = [SKAction sequence:@[[SKAction fadeAlphaTo:0.0 duration:10.0],[SKAction removeFromParent]]];
        [heven runAction:fadeOut];
        
    } else {
        [backgroundNode removeAllChildren];
        table.hidden = YES;
        messageViewController.view.hidden = YES;
        
        //セントラルはこっち
        backgroundNode.texture = [SKTexture textureWithImageNamed:@"heven.jpg"];
        
        CGSize size = CGSizeMake(self.size.width*0.6, self.size.width*0.6*0.8);
        NSString *mes = @"あなたは襲撃されました。";
        if(isExcute) mes = @"あなたは処刑されました。";
        SKSpriteNode *messageNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:[NSString stringWithFormat:@"%@以後ゲームが終了するまで話をすることができません。",mes] fontSize:size.height*0.11];
        messageNode.position = CGPointMake(0, 0);
        [backgroundNode addChild:messageNode];
        
        [self backgroundMorphing:[SKTexture textureWithImageNamed:@"heven.jpg"] time:10.0];
    }
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
        [self setTableData:[BWUtility getMyRoleId:infoDic]];
        if(!table.superview) {
            [self.view addSubview:table];
        }
        table.hidden = NO;
    }
    
    if([node.name isEqualToString:@"check"]) {
        [checkButton removeFromParent];
        waitLabelNode = [[SKLabelNode alloc]init];
        waitLabelNode.text = @"全員の確認待ち";
        waitLabelNode.fontColor = [UIColor blackColor];
        waitLabelNode.fontSize = checkButton.size.height*0.9;
        waitLabelNode.position = checkButton.position;
        [backgroundNode addChild:waitLabelNode];
        
        if(isPeripheral) {
            //ペリフェラルは直接処理
            checkList[[BWUtility getMyPlayerId:infoDic]] = @YES;
            if([self isAllOkCheckList]) {
                [self nightStart];
            }
        } else {
            //セントラルはかくにん通知を送る
            //投票結果確認通知「checkVoting:A..A」
            [centralManager sendNormalMessage:[NSString stringWithFormat:@"checkVoting:%@",[BWUtility getIdentificationString]] interval:5.0 timeOut:15.0 firstWait:0.0];
        }
    }
    
    if([node.name isEqualToString:@"end"]) {
        BWTopScene *scene = [[BWTopScene alloc]initWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
        [self.view presentScene:scene transition:transition];
        return;
    }
}

-(void)setTableData :(NSInteger)myRoleId {
    //TODO::テーブルデータ 基本的には役職のIDだが、処刑投票は-1となっている
    tableArray = [NSMutableArray array];
    NSInteger myPlayerId = [BWUtility getMyPlayerId:infoDic];
    NSMutableArray *playerArray = infoDic[@"players"];
    for(NSInteger i=0;i<playerArray.count;i++) {
        if(![playerArray[i][@"isLive"]boolValue]) continue;//死亡者は含めない
        
        NSInteger roleId = [playerArray[i][@"roleId"]integerValue];
        if(myRoleId == RoleWerewolf) {//人狼の場合は仲間の人狼以外の襲撃対象を入れる
            if(roleId != RoleWerewolf) {
                [tableArray addObject:playerArray[i]];
            }
        }
        if(myRoleId == RoleFortuneTeller || myRoleId == RoleBodyguard || myRoleId == -1) {
            if(i != myPlayerId) {
                [tableArray addObject:playerArray[i]];
            }
        }
    }
    tableRoleId = myRoleId;
    tableHeaderString = [BWUtility getCardInfofromId:(int)myRoleId][@"tableString"];
    
    [table reloadData];
}

-(void)doRoleAction {
    [table removeFromSuperview];
    [coverView removeFromSuperview];
    if(!isPeripheral) {
        //セントラルは命令をペリフェラルに送信
        NSString *message = [NSString stringWithFormat:@"action:%d/%d/%d",(int)tableRoleId,(int)[BWUtility getMyPlayerId:infoDic],(int)targetIndex];
        [centralManager sendNormalMessage:message interval:5.0 timeOut:15.0 firstWait:0.0];
    } else {
        //ペリフェラルは即実行
        [self processRoleAction:tableRoleId actionPlayerId:[BWUtility getMyPlayerId:infoDic] targetPlayerId:targetIndex];
    }
    didAction = YES;
    
    [actionButtonNode removeFromParent];
}

-(void)processRoleAction :(NSInteger)roleId actionPlayerId:(NSInteger)actionPlayerId targetPlayerId:(NSInteger)targetPlayerId {//ペリフェラルのみ
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
    if(roleId == RoleBodyguard) {
        [bodyguardArray addObject:@(targetPlayerId)];
        //メッセージを送信
        NSMutableArray *playerArray = infoDic[@"players"];
        NSString *message = [NSString stringWithFormat:@"「%@」さんを守ります。",playerArray[targetPlayerId][@"name"]];
        
        [self sendGMMessage:message receiverId:playerArray[actionPlayerId][@"identificationId"]];
    }
    if(roleId == -1) {//投票アクション
        NSMutableDictionary *voteDic = [@{@"voter":@(actionPlayerId),@"voteder":@(targetPlayerId),@"count":@0}mutableCopy];
        [votingArray addObject:voteDic];
        if([self isAllVoting]) {
            [self finishVoting];
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
        NSInteger targetRoleId = [infoDic[@"players"][i][@"roleId"]integerValue];
        //人狼同士
        if(roleId == RoleWerewolf && targetRoleId == RoleWerewolf) {
            [shouldSenderId addObject:infoDic[@"players"][i][@"identificationId"]];
        }
    }
    return [shouldSenderId copy];
}

#pragma mark - messageDelegate

-(void)didReceivedMessage:(NSString *)message {//ペリフェラル->セントラル受信処理
    //central
    //ペリフェラルから受け取ったメッセージから、自分と同じグループチャットがあったら反映
    //ただし自分自信はすでに反映されているのでむし
    
    if(winner != WinnerNone) return;//ゲーム終了後は無視
    
    //chatreceive:A..A/T...T
    //chatreceive:G..G/A..A/T..T
    //セントラルは自分が死んだら、ゲーム終了後まで信号を受信しない
    if([infoDic[@"players"][[BWUtility getMyPlayerId:infoDic]][@"isLive"]boolValue]) {
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
        
        //ペリフェラルからの朝開始＋犠牲者通知「afternoonStart:2,4」数値は犠牲者のプレイヤーID
        if([[BWUtility getCommand:message] isEqualToString:@"afternoonStart"]) {
            if(phase == PhaseNightFinish) {
                //TODO::ここでセントラル側のvictimArrayを更新
                NSArray *victimString = [[BWUtility getCommandContents:message][0] componentsSeparatedByString:@","];
                for(NSInteger i=0;i<victimString.count;i++) {
                    if([victimString[i] isEqualToString:@""]) continue;
                    [victimArray addObject:@([victimString[i]integerValue])];
                }
                [self afternoonStart];
            }
        }
        
        //ペリフェラルからの投票結果通知「voteResult:1/-1/0,0,1/1,5,2/2,8,0/.../8,1,1」何回目の投票か、最多得票者、投票内訳(投票者、投票先、投票者に何票はいったか)の順番（最多得票者が-1の場合は決戦orランダム、生存者分のみ)
        if([[BWUtility getCommand:message] isEqualToString:@"voteResult"]) {
            if(phase == PhaseAfternoonFinish) {
                //ここで投票履歴を取得
                votingArray = [NSMutableArray array];
                NSArray *components = [BWUtility getCommandContents:message];
                excutionerId = [components[1]integerValue];
                voteCount = [components[0]integerValue];
                for(NSInteger i=2;i<[components count];i++) {
                    NSArray *idStrings = [components[i] componentsSeparatedByString:@","];
                    NSInteger voterId = [idStrings[0]integerValue];
                    NSInteger votederId = [idStrings[1]integerValue];
                    NSInteger count = [idStrings[2]integerValue];
                    [votingArray addObject:[@{@"voter":@(voterId),@"voteder":@(votederId),@"count":@(count)}mutableCopy]];
                }
                
                [self finishVoting];
            }
        }
        
        //ペリフェラルからの夜開始通知「nightStart:」
        if([[BWUtility getCommand:message] isEqualToString:@"nightStart"]) {
            if(phase == PhaseVotingFinish) {
                [self nightStart];
            }
        }
    }
    
    //ペリフェラルからのゲーム終了通知「gameEnd:W」Wは処理者チームID (utilityを参照）
    if([[BWUtility getCommand:message] isEqualToString:@"gameEnd"]) {
        winner = [[BWUtility getCommandContents:message][0]integerValue];
        [self gameEnd];
    }
}

-(void)didReceiveMessage:(NSString *)message {//セントラル->ペリフェラル受信処理
    //peripheral
    //セントラルから受け取ったメッセージを送るべき相手に送信
    //その後自分と同じグループと同じグループチャットがあったら反映（ただし自分はむし）
    
    if(winner != WinnerNone) return;//ゲーム終了後は無視
    
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
    
    //セントラルによる夜時間終了通知「nightFinish:A..A」
    if([[BWUtility getCommand:message] isEqualToString:@"nightFinish"]) {
        NSString *identificationId = [BWUtility getCommandContents:message][0];
        NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
        checkList[playerId] = @YES;
        if([self isAllOkCheckList]) {
            [self afternoonStart];
        }
    }
    
    //セントラルによる投票結果確認通知「checkVoting:A..A」
    if([[BWUtility getCommand:message] isEqualToString:@"checkVoting"]) {
        NSString *identificationId = [BWUtility getCommandContents:message][0];
        NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
        checkList[playerId] = @YES;
        if([self isAllOkCheckList]) {
            [self nightStart];
        }
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
                [peripheralManager sendNormalMessage:mes toIdentificationId:shouldSendIds[i] interval:5.0 timeOut:15.0 firstWait:i*0.07+j*0.1];
            }
        } else {
            //まずはペリフェラルに知らせる
            NSString *mes = [NSString stringWithFormat:@"chatsend:%@/%@",[BWUtility getIdentificationString],array[j]];
            [centralManager sendNormalMessage:mes interval:5.0 timeOut:15.0 firstWait:j*0.1];
        }
    }
}

-(void)update:(NSTimeInterval)currentTime {
    BWAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    BWViewController *vc = (BWViewController*)appDelegate.window.rootViewController;
    [vc addPlayersInfo:infoDic[@"players"]];
}

#pragma mark - TimerDelegate
-(void)didDecreaseTime:(NSInteger)seconds {
    if(seconds == 0) {
        if(phase == PhaseNight) {
            [self finishNight];
            return;
        } else if(phase == PhaseAfternoon) {
            [self finishAfternoon];
            return;
        }
    }
    
    if(seconds == 10 && phase == PhaseAfternoon) {
        [self backgroundMorphing:[SKTexture textureWithImageNamed:@"evening.jpg"] time:10.0];
    }
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
    
    NSString *message = @"";
    if(tableRoleId == RoleWerewolf) {
        message = [NSString stringWithFormat:@"「%@」さんを噛みますか？",infoDic[@"players"][targetIndex][@"name"]];
    }
    if(tableRoleId == RoleFortuneTeller) {
        message = [NSString stringWithFormat:@"「%@」さんを占いますか？",infoDic[@"players"][targetIndex][@"name"]];
    }
    if(tableRoleId == -1) {
        message = [NSString stringWithFormat:@"「%@」さんに投票しますか？",infoDic[@"players"][targetIndex][@"name"]];
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

// ヘッダー配置
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // ヘッダー画像配置
    UILabel *label = [[UILabel alloc]init];
    
    NSString *string = tableHeaderString;
    
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
