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

#import "BWGorgeousTableView.h"
#import "BWVoteCell.h"

#import "LWBonjourManager.h"

typedef NS_ENUM(NSInteger,Phase) {
    PhaseNight,
    PhaseNightFinish,
    PhaseMorning,
    PhaseAfternoon,
    PhaseAfternoonFinish,
    PhaseVotingFinish,
};

typedef NS_ENUM(NSInteger,TableMode) {
    TableModeNormal,
    TableModeVoteResult,
    TableModeHistory,
};

const NSInteger minuteSeconds = 20;

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
    NSInteger wolfDidActionindex;
    NSInteger voteCount;
    NSMutableArray *victimArray;//これは情報をセントラルでも共有する
    NSMutableArray *bodyguardArray;
    NSMutableArray *votingArray;//投票履歴1日分 (リフレッシュ時にinfoDic[@"voting"]に書き込んでいく)
    
    
    SKSpriteNode *checkButton;//投票確認用ぼたんなど
    SKLabelNode *waitLabelNode;//かくにん待ち表示用
    SKSpriteNode *messageFrameNode;
    SKSpriteNode *voteCheckNode;
    SKSpriteNode *victimCheckNode;
    
    NSInteger excutionerId;
    NSMutableArray *afternoonVictimArray;//猫又とか
    
    BWGorgeousTableView *table;
    NSMutableArray *tableArray;
    NSString *tableHeaderString;
    NSInteger tableRoleId;
    
    
    UIView *coverView;
    UIView *afternoonView;
    
    SKView *deadPeripheralCoverView;
    
    TableMode tableMode;
    
    Winner winner;
    
    NSInteger voteMaxCount;
    
    NSInteger lastNightGuardIndex;//連続護衛禁止用の変数 セントラル側で管理しておく
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
            if(nFox <= 0) {
                return WinnerWerewolf;
            } else {
                return WinnerFox;
            }
        }
    }
    return WinnerNone;
}

-(void)setCentralOrPeripheral:(BOOL)_isPeripheral :(NSMutableDictionary*)_infoDic {//共通　情報をリレーする
    isPeripheral = _isPeripheral;
    
    infoDic = _infoDic;
    
    winner = WinnerNone;
    
    sendManager = [BWSendMessageManager sharedInstance];
    sendManager.delegate = self;
    
    if(isPeripheral) {
        [self resetCheckList];
        voteCount = 1;
    }
    
    day = 1;
    excutionerId = -1;
    phase = PhaseNight;
    voteMaxCount = 4;
    lastNightGuardIndex = -1;
    
    CGFloat margin = self.size.height*0.02;
    CGFloat statusHeight = 22;
    CGFloat timerHeight = self.size.height*0.1;
    messageViewController = [BWMessageViewController sharedInstance:infoDic];
    messageViewController.view.frame = CGRectMake(margin, margin*2+timerHeight+statusHeight, self.size.width - margin*2, self.size.height - margin*3 - timerHeight - statusHeight);
    messageViewController.delegate = self;
    
    timer = [[BWTimer alloc]init];
    [timer setSeconds:[infoDic[@"rules"][@"nightTimer"]integerValue]*minuteSeconds];
    timer.delegate = self;
    
    CGFloat tableMargin = self.size.height*0.05;
    table = [[BWGorgeousTableView alloc]initWithFrame:CGRectMake(tableMargin, tableMargin + statusHeight, self.size.width-tableMargin*2,self.size.height - (statusHeight+tableMargin*3+self.size.height*0.1))];
    [table setViewDesign:self];
    
    table.tableView.rowHeight = table.frame.size.height/6;
    
    didAction = NO;
    [self resetDidActionPeripheralArray];
    
    [self initBackground];
    
    
    [self nightStart];
}

-(void)initBackground {//共通　背景の描画
    //今の実装では初日の夜にしか呼ばれない
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
    explain.zPosition = 1.0;
    [backgroundNode addChild:explain];
    
    timer.size = CGSizeMake(timerHeight*2.4, timerHeight);
    [timer initNodeWithFontColor:[UIColor whiteColor]];
    timer.position = CGPointMake(explain.position.x + explain.size.width/2 + timer.size.width/2 + margin, explain.position.y);
    [timer removeFromParent];
    timer.zPosition = 1.0;
    [backgroundNode addChild:timer];
    
    
    NSInteger roleId = [BWUtility getMyRoleId:infoDic];
    NSString *buttonTitle = @"";
    NSString *buttonName = @"action";
    
    if(roleId == RoleWerewolf) buttonTitle = @"噛む";
    if(roleId == RoleFortuneTeller) buttonTitle = @"占う";
    if(roleId == RoleBodyguard) buttonTitle = @"守る";
    
    CGFloat buttonSizeWidth = self.size.width-(margin*4+explain.size.width+timer.size.width);
    
    actionButtonNode = [BWUtility makeButton:buttonTitle size:CGSizeMake(buttonSizeWidth,timer.size.height*0.9) name:buttonName position:CGPointMake(self.size.width/2-buttonSizeWidth/2-margin, explain.position.y)];
    actionButtonNode.zPosition = 1.0;
    
    
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
    
    if(table.superview) {
        [table removeFromSuperview];
        table.hidden = YES;
    }
    
    didAction = NO;
    if(isPeripheral) {
        [self resetDidActionPeripheralArray];
    }
    [self backgroundMorphing:[SKTexture textureWithImageNamed:@"night.jpg"] time:1.0];
    NSInteger roleId = [BWUtility getMyRoleId:infoDic];
    if([[BWUtility getCardInfofromId:(int)roleId][@"hasTable"]boolValue]) {
        if(!actionButtonNode.parent) {
            if(roleId == RoleWerewolf && day != 1) {
                [backgroundNode addChild:actionButtonNode];
            }
            if(roleId == RoleBodyguard && day != 1) {
                [backgroundNode addChild:actionButtonNode];
            }
            if(roleId == RoleFortuneTeller) {
                if(day == 1 && [infoDic[@"rules"][@"fortuneMode"]integerValue] == FortuneTellerModeFree) {
                    [backgroundNode addChild:actionButtonNode];
                }
                if(day >= 2) {
                    [backgroundNode addChild:actionButtonNode];
                }
            }
        }
    }
    explain.texture = [BWUtility getCardTexture:roleId];
    
    if(day >= 2) {
        [voteCheckNode removeFromParent];
        if(!isPeripheral || [infoDic[@"players"][[BWUtility getMyPlayerId:infoDic]][@"isLive"]boolValue]) {
            messageViewController.view.hidden = NO;
        }
        [waitLabelNode removeFromParent];
        [timer setSeconds:[infoDic[@"rules"][@"nightTimer"]integerValue]*minuteSeconds];
        
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
        //道連れ
        for(NSInteger i=0;i<afternoonVictimArray.count;i++) {
            NSInteger index = [afternoonVictimArray[i][@"index"]integerValue];
            infoDic[@"players"][index][@"isLive"] = @NO;
            if([BWUtility getMyPlayerId:infoDic] == index) {
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
                    
                    if([infoDic[@"players"][i][@"roleId"]integerValue] == RoleFortuneTeller && [infoDic[@"rules"][@"fortuneMode"]integerValue] == FortuneTellerModeRevelation) {
                        //TODO::占い師　お告げ
                        //自分以外、狼、狐以外からランダムに選ぶ
                        NSInteger firstNightFortuneId = 0;
                        NSMutableArray *indices = [NSMutableArray array];
                        for(NSInteger j=0;j<[infoDic[@"players"] count];j++) {
                            if(j == i) continue;
                            NSInteger roleId = [infoDic[@"players"][j][@"roleId"]integerValue];
                            if(roleId != RoleWerewolf && roleId != RoleFox) {
                                [indices addObject:@(j)];
                            }
                        }
                        firstNightFortuneId = [indices[[BWUtility getRandInteger:indices.count]]integerValue];
                        
                        [NSObject performBlock:^{
                            NSString *result = @"「人間 ○」";
                            NSString *mes = [NSString stringWithFormat:@"お告げ結果「%@」さんは%@でした",infoDic[@"players"][firstNightFortuneId][@"name"],result];
                            [self sendGMMessage:mes receiverId:infoDic[@"players"][i][@"identificationId"]];
                        } afterDelay:2.0];
                    }
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
                [sendManager sendMessageForAllCentrals:mes];
                [self gameEnd];
                return;
            }
            
            //２日目以降は夜開始を通知「nightStart:」
            [sendManager sendMessageForAllCentrals:@"nightStart:"];
            [self resetCheckList];
        }
    }
}

-(void)afternoonStart {
    phase = PhaseAfternoon;
    [victimCheckNode removeFromParent];
    [waitLabelNode removeFromParent];
    //リフレッシュ操作を行う
    excutionerId = -1;
    afternoonVictimArray = [NSMutableArray array];
    
    //backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    [self backgroundMorphing:[SKTexture textureWithImageNamed:@"afternoon.jpg"] time:1.0];
    explain.texture = [SKTexture textureWithImageNamed:@"back_card.jpg"];
    [timer setSeconds:[infoDic[@"rules"][@"timer"]integerValue]*minuteSeconds];
    votingArray = [NSMutableArray array];
    
    if(isPeripheral) {
        //ペリフェラルは昼開始を通知
        
        //TODO::勝利判定を行い、ゲーム終了の場合は終了通知を送る
        if([self checkWinner] != WinnerNone) {
            //ゲームセット
            //ゲーム終了を通知「gameEnd:W」
            winner = [self checkWinner];
            NSString *mes = [NSString stringWithFormat:@"gameEnd:%d",(int)winner];
            [sendManager sendMessageForAllCentrals:mes];
            [self gameEnd];
            return;
        }
        
        //全員の犠牲者受信完了を通知「victimCheckFinish:」
        [sendManager sendMessageForAllCentrals:@"victimCheckFinish:"];
        
    }
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
    
    
    //[self backgroundMorphing:[SKTexture textureWithImageNamed:@"morning.jpg"] time:1.0];
    //backgroundNode.texture = [SKTexture textureWithImageNamed:@"morning.jpg"];
    
    if(isPeripheral) {
        //ペリフェラルは直接夜時間終了処理を行う
        NSInteger myPlayerId = [BWUtility getMyPlayerId:infoDic];
        checkList[myPlayerId] = @YES;
        if([self isAllOkCheckList]) {
            [self morning];
        }
    } else {
        //セントラルは夜時間終了を通知「nightFinish:A..A」
        NSString *mes = [NSString stringWithFormat:@"nightFinish:%@",[BWUtility getIdentificationString]];
       
        [sendManager sendMessageForPeripheral:mes];
        //ペリフェラルからの朝通知を待つ
    }
}

-(void)morning {
    //犠牲者を全員で確認して同期を取ってからafternoonに行く
    phase = PhaseMorning;
    voteCount = 1;
    day++;
    [self backgroundMorphing:[SKTexture textureWithImageNamed:@"morning.jpg"] time:1.0];
    
    if(isPeripheral) {
        [self resetCheckList];
        
        [self resetDidActionPeripheralArray];
        
        //TODO::朝の犠牲者処理 きつねとかは占いアクション中に処理してしまう
        if(wolfTargetIndex == -1 && day != 2) {
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
            //猫又の場合は噛んだ人も道づれ
            if([infoDic[@"players"][wolfTargetIndex][@"roleId"]integerValue] == RoleCat) {
                [victimArray addObject:@(wolfDidActionindex)];
            }
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
        //犠牲者をシャッフルする
        victimArray = [BWUtility getRandomArray:victimArray];
        
        //朝開始＋犠牲者通知「afternoonStart:2,4」数値は犠牲者のプレイヤーID
        NSString *mes = [NSString stringWithFormat:@"afternoonStart:%@",[victimArray componentsJoinedByString:@","]];
        [sendManager sendMessageForAllCentrals:mes];
    }
    
    //犠牲者を表示　＋　確認ボタン これを全員が押したら昼に移動
    CGSize size = CGSizeMake(self.size.width*0.8, self.size.width*0.8/2);
    NSString *victimString = @"いません";
    for(NSInteger i=0;i<victimArray.count;i++) {
        if(i==0) victimString = [NSString stringWithFormat:@"「%@」さん",infoDic[@"players"][[victimArray[i]integerValue]][@"name"]];
        if(i > 0) victimString = [NSString stringWithFormat:@"%@「%@」さん",victimString,infoDic[@"players"][[victimArray[i]integerValue]][@"name"]];
    }
    victimCheckNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:[NSString stringWithFormat:@"%d日目の朝になりました。昨晩の犠牲者は%@でした。",(int)day,victimString] fontSize:size.height*0.09];
    victimCheckNode.position = CGPointMake(0, 0);
    [backgroundNode addChild:victimCheckNode];
    
    CGFloat margin = self.size.height*0.05;
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    checkButton = [BWUtility makeButton:@"確認" size:buttonSize name:@"victimCheck" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
    [backgroundNode addChild:checkButton];
    
    
    if([sendManager isPeripheral]) {
        [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"-1/-/GM/-/%@",[NSString stringWithFormat:@"%d日目の朝になりました。昨晩の犠牲者は%@でした。",(int)day,victimString]]];
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
    if(waitLabelNode.parent) {
        [waitLabelNode removeFromParent];
    }
    if(!isPeripheral || [infoDic[@"players"][[BWUtility getMyPlayerId:infoDic]][@"isLive"]boolValue]) {
        table.hidden = NO;
    }
}

-(void)finishVoting {
    //投票終了　投票結果確認フェーズ
    phase = PhaseVotingFinish;
    if(isPeripheral) {
        [self resetDidActionPeripheralArray];
        [self resetCheckList];
        
        
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
        
        //TODO::決選投票について（4回目の投票は同票ならランダム）
        if(maxIndices.count >= 2) {
            excutionerId = -1;
            if(voteCount >= 4) {
                excutionerId = [maxIndices[[BWUtility getRandInteger:maxIndices.count]]integerValue];
            }
        } else {
            excutionerId = [maxIndices[0]integerValue];
        }
        
        //TODO::処刑による犠牲者処理
        if(excutionerId != -1) {
            //猫又チェック
            if([infoDic[@"players"][excutionerId][@"roleId"]integerValue] == RoleCat) {
                NSMutableArray *liver = [self getLivePlayerIds];
                [liver removeObject:@(excutionerId)];
                NSInteger catDeathIndex = [liver[[BWUtility getRandInteger:liver.count]]integerValue];
                [afternoonVictimArray addObject:@{@"index":@(catDeathIndex),@"reasonRoleId":@(RoleCat)}];
            }
        }
      
        NSString *message = [NSString stringWithFormat:@"voteResult:%d/%d",(int)voteCount,(int)excutionerId];
        for(NSInteger i=0;i<votingArray.count;i++) {
            NSInteger votederId = [votingArray[i][@"voteder"]integerValue];
            NSInteger voterId = [votingArray[i][@"voter"]integerValue];
            NSInteger count = [counter[voterId]integerValue];
            message = [NSString stringWithFormat:@"%@/%d,%d,%d",message,(int)voterId,(int)votederId,(int)count];
        }
        [sendManager sendMessageForAllCentrals:message];
    }
    
    
    
    //投票結果表示　＋　確認ボタン表示 + 投票結果の保存
    //TODO::投票結果の保存
    tableMode = TableModeVoteResult;
    table.tableView.rowHeight = table.frame.size.width/1446*244;
    table.tableView.allowsSelection = NO;
    if(!table.superview) {
        [self.view addSubview:table];
    }
    table.hidden = NO;
    [table.tableView reloadData];
    
    
    CGFloat margin = self.size.height*0.05;
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    checkButton = [BWUtility makeButton:@"確認" size:buttonSize name:@"check" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
    [backgroundNode addChild:checkButton];
    
    
    if([sendManager isPeripheral]) {
        NSString *message = @"";
        for(NSInteger i=0;i<votingArray.count;i++) {
            message = [NSString stringWithFormat:@"%@\r\n%@",message,[BWUtility getVoteResultFormatString:votingArray[i] infoDic:infoDic]];
        }
        
        if(excutionerId == -1) {
            message = [NSString stringWithFormat:@"%@\r\n%d日目%d回目投票結果 同票のため再投票します。（あと%d回)",message,(int)day,(int)voteCount,(int)voteMaxCount-(int)voteCount];
        } else {
            message = [NSString stringWithFormat:@"%@\r\n%d日目%d回目投票結果「%@」さんが追放されました。",message,(int)day,(int)voteCount,infoDic[@"players"][excutionerId][@"name"]];
        }
        [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"-1/-/GM/-/%@",message]];
    }
}

-(void)beforeNight {
    //道連れ報告など、夜に入る直前の処理
    if(isPeripheral) {
        //ペリフェラルは全員に道連れを通知 (nightstartの代わりに)
        //・夜時間開始前に道連れを通知「afternoonVictim:1,8/2,?」プレイヤーID,死因となる役職IDのセットを死亡者分
        NSString *mes = @"afternoonVictim:";
        for(NSInteger i=0;i<afternoonVictimArray.count;i++) {
            mes = [NSString stringWithFormat:@"%@%@,%@",mes,afternoonVictimArray[i][@"index"],afternoonVictimArray[i][@"reasonRoleId"]];
            if(i != afternoonVictimArray.count-1) {
                mes = [NSString stringWithFormat:@"%@/",mes];
            }
        }
        [sendManager sendMessageForAllCentrals:mes];
        
        [self resetCheckList];
    }
    
    //道連れを表示 + 確認ボタン表示
    CGSize size = CGSizeMake(self.size.width*0.7, self.size.width*0.7*0.5);
    NSString *mes = @"";
    for(NSInteger i=0;i<afternoonVictimArray.count;i++) {
        NSString *name = infoDic[@"players"][[afternoonVictimArray[i][@"index"]integerValue]][@"name"];
        NSString *reasonString = @"";
        NSInteger reasonRoleId = [afternoonVictimArray[i][@"reasonRoleId"]integerValue];
        if(reasonRoleId == RoleCat) {
            reasonString = @"猫又の呪いで死亡しました。";
        }
        
        mes = [NSString stringWithFormat:@"%@「%@」さんは%@",mes,name,reasonString];
    }
    messageFrameNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:[NSString stringWithFormat:@"%@",mes] fontSize:size.height*0.09];
    messageFrameNode.position = CGPointMake(0, messageFrameNode.size.height*0.8);
    if(!messageFrameNode.parent) {
        [backgroundNode addChild:messageFrameNode];
        messageFrameNode.hidden = NO;
    }
    
    CGFloat margin = self.size.height*0.05;
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    checkButton = [BWUtility makeButton:@"確認" size:buttonSize name:@"afternoonVictimCheck" position:CGPointMake(0,-self.size.height/2+margin+buttonSize.height/2)];
    if(!checkButton.parent) {
        [backgroundNode addChild:checkButton];
        checkButton.hidden = NO;
    }
    
    if([sendManager isPeripheral]) {
        [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"-1/-/GM/-/%@",mes]];
    }
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
    
    if([sendManager isPeripheral]) {
        [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"-1/-/GM/-/%@",mes]];
    }
}

-(void)dead:(BOOL)isExcute {
    SKTexture *deadTexture = [SKTexture textureWithImageNamed:@"bg_dead.png"];
    if(isExcute) {
        deadTexture = [SKTexture textureWithImageNamed:@"bg_batankyu.jpg"];
    }
    SKTexture *hevenTexture = [SKTexture textureWithImageNamed:@"bg_heaven.jpg"];
    
    if(isPeripheral) {
        //ペリフェラルは死亡後も信号のやり取りを行う必要がある
        deadPeripheralCoverView = [[SKView alloc]initWithFrame:self.view.frame];
        SKScene *coverScene = [[SKScene alloc]initWithSize:self.size];
        [self.view addSubview:deadPeripheralCoverView];
        [deadPeripheralCoverView presentScene:coverScene];
        
        SKSpriteNode *coverBackgroundNode = [[SKSpriteNode alloc]init];
        coverBackgroundNode.size = coverScene.size;
        coverBackgroundNode.position = CGPointMake(coverScene.size.width/2, coverScene.size.height/2);
        coverBackgroundNode.texture = hevenTexture;
        [coverScene addChild:coverBackgroundNode];

        
        CGSize size = CGSizeMake(self.size.width*0.7, self.size.width*0.7*0.5);
        NSString *mes = @"あなたは襲撃されました。";
        if(isExcute) mes = @"あなたは追放されました。";
        SKSpriteNode *messageNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:[NSString stringWithFormat:@"%@以後ゲームが終了するまで話をすることができません。",mes] fontSize:size.height*0.09];
        messageNode.position = CGPointMake(0, messageNode.size.height*0.8);
        [coverBackgroundNode addChild:messageNode];
        
        SKSpriteNode *heven = [[SKSpriteNode alloc]init];
        heven.texture = deadTexture;
        heven.size = coverBackgroundNode.size;
        [coverBackgroundNode addChild:heven];
        SKAction *fadeOut = [SKAction sequence:@[[SKAction fadeAlphaTo:0.0 duration:20.0],[SKAction removeFromParent]]];
        [heven runAction:fadeOut];
        
    } else {
        [backgroundNode removeAllChildren];
        table.hidden = YES;
        messageViewController.view.hidden = YES;
        
        //セントラルはこっち
        backgroundNode.texture = deadTexture;
        
        CGSize size = CGSizeMake(self.size.width*0.7, self.size.width*0.7*0.5);
        NSString *mes = @"あなたは襲撃されました。";
        if(isExcute) mes = @"あなたは追放されました。";
        SKSpriteNode *messageNode = [BWUtility makeMessageNodeWithBoldrate:1.0 size:size text:[NSString stringWithFormat:@"%@以後ゲームが終了するまで話をすることができません。",mes] fontSize:size.height*0.09];
        messageNode.position = CGPointMake(0, messageNode.size.height*0.8);
        [backgroundNode addChild:messageNode];
        
        [self backgroundMorphing:hevenTexture time:20.0];
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
    
    if([node.name isEqualToString:@"victimCheck"]) {
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
                [self afternoonStart];
            }
        } else {
            //セントラルはかくにん通知を送る
            //犠牲者確認通知「checkVictim:A..A」
            NSString *mes = [NSString stringWithFormat:@"checkVictim:%@",[BWUtility getIdentificationString]];
            [sendManager sendMessageForPeripheral:mes];
            
        }
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
                if(excutionerId == -1) {
                    //再投票
                    voteCount++;
                    votingArray = [NSMutableArray array];
                    [sendManager sendMessageForAllCentrals:@"nightStart:"];
                    [self finishAfternoon];
                } else {
                    if(afternoonVictimArray.count <= 0) {
                        [self nightStart];
                    } else {
                        //道連れが発生していたら表示する
                        [self beforeNight];
                    }
                }
            }
        } else {
            //セントラルはかくにん通知を送る
            //投票結果確認通知「checkVoting:A..A」
            NSString *mes = [NSString stringWithFormat:@"checkVoting:%@",[BWUtility getIdentificationString]];
            [sendManager sendMessageForPeripheral:mes];
    
        }
    }
    
    //afternoonVictimCheck
    if([node.name isEqualToString:@"afternoonVictimCheck"]) {
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
            //・夜直前の道連れ確認通知「afternoonVictimCheck:C..C」
            NSString *mes = [NSString stringWithFormat:@"afternoonVictimCheck:%@",[BWUtility getIdentificationString]];
            [sendManager sendMessageForPeripheral:mes];
        }
    }
    
    if([node.name isEqualToString:@"end"]) {
     
        [BWSendMessageManager resetSharedInstance];
        
        [timer stopTimer];
        timer.delegate = nil;
        [timer removeAllActions];
        [timer removeFromParent];
        timer = nil;
        [BWMessageViewController resetSharedInstance];
        BWTopScene *scene = [[BWTopScene alloc]initWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
        [self.view presentScene:scene transition:transition];
        return;
    }
}

-(void)setTableData :(NSInteger)myRoleId {
    tableMode = TableModeNormal;
    table.tableView.allowsSelection = YES;
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
    
    table.tableView.rowHeight = table.frame.size.height/6;
    
    tableMode = TableModeNormal;
    
    [table.tableView reloadData];
    
    
}

-(void)doRoleAction {
    [table removeFromSuperview];
    [coverView removeFromSuperview];
    
    if(tableRoleId == RoleBodyguard) {
        //ボディーガードは今日の護衛先を記憶しておく
        lastNightGuardIndex = targetIndex;
    }
    
    if(!isPeripheral) {
        //セントラルは命令をペリフェラルに送信
        NSString *message = [NSString stringWithFormat:@"action:%d/%d/%d",(int)tableRoleId,(int)[BWUtility getMyPlayerId:infoDic],(int)targetIndex];
        [sendManager sendMessageForPeripheral:message];
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
            if([infoDic[@"players"][targetPlayerId][@"roleId"]integerValue] == RoleFox) {
                //狐は溶ける
                [victimArray addObject:@(targetPlayerId)];
            }
        }
        [self sendGMMessage:message receiverId:infoDic[@"players"][actionPlayerId][@"identificationId"]];
    }
    if(roleId == RoleWerewolf) {
        wolfTargetIndex = targetPlayerId;//噛み先を保存
        wolfDidActionindex = actionPlayerId;//噛んだ人も保存（猫又とか）
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
        //GMメッセージ（peripheral(gm)->central）「chatreceive:G..G/C..C/M..M」G..GはgmId C..Cは送り先central
        NSArray *messages = [self divideMessage:message];
        for(NSInteger i=0;i<messages.count;i++) {
            NSString *mes = [NSString stringWithFormat:@"chatreceive:%@/%@/%@",[messageViewController getGmId],identificationId,messages[i]];
            [sendManager sendMessageWithAddressId:mes toId:identificationId];
            
        }
    }
    
    //ログを送信
    if([sendManager isPeripheral]) {
        NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
        NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
        [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"%d/-/GM/-/%@",(int)roleId,message]];
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
        //共有者同士
        if(roleId == RoleJointOwner && targetRoleId == RoleJointOwner) {
            [shouldSenderId addObject:infoDic[@"players"][i][@"identificationId"]];
        }
        //狐同士
        if(roleId == RoleFox && targetRoleId == RoleFox) {
            [shouldSenderId addObject:infoDic[@"players"][i][@"identificationId"]];
        }
    }
    return [shouldSenderId copy];
}


-(NSMutableArray*)getLivePlayerIds {
    NSMutableArray *players = infoDic[@"players"];
    NSMutableArray *result = [NSMutableArray array];
    for(NSInteger i=0;i<players.count;i++) {
        if([players[i][@"isLive"]boolValue]) {
            [result addObject:@(i)];
        }
    }
    return result;
}

#pragma mark - messageManagerDelegate

- (void)didReceiveMessage:(NSString *)message senderId:(NSString *)senderId {
    if(![sendManager isPeripheral]) {
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
                    [self morning];
                }
            }
            
            //ペリフェラルからの投票結果通知「voteResult:1/-1/0,0,1/1,5,2/2,8,0/.../8,1,1」何回目の投票か、最多得票者、投票内訳(投票者、投票先、投票者に何票はいったか)の順番（最多得票者が-1の場合は決戦orランダム、生存者分のみ)
            if([[BWUtility getCommand:message] isEqualToString:@"voteResult"]) {
                if(phase == PhaseAfternoonFinish) {
                    //TODO::ここで投票履歴を取得
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
                    if(excutionerId == -1) {
                        //再投票
                        votingArray = [NSMutableArray array];
                        voteCount++;
                        [self finishAfternoon];
                    } else {
                        [self nightStart];
                    }
                }
            }
            
            //・夜時間開始前に道連れを通知「afternoonVictim:1,8/2,?」プレイヤーID,死因となる役職IDのセットを死亡者分
            if([[BWUtility getCommand:message] isEqualToString:@"afternoonVictim"]) {
                if(phase == PhaseVotingFinish) {
                    //TODO::セントラルはここで道連れを保存
                    NSArray *components = [BWUtility getCommandContents:message];
                    for(NSInteger i=0;i<components.count;i++) {
                        NSArray *values = [components[i] componentsSeparatedByString:@","];
                        [afternoonVictimArray addObject:@{@"index":@([values[0]integerValue]),@"reasonRoleId":@([values[1]integerValue])}];
                    }
                    
                    [self beforeNight];
                }
            }
            
            //ペリフェラルからの犠牲者受信完了を通知「victimCheckFinish:」
            if([[BWUtility getCommand:message] isEqualToString:@"victimCheckFinish"]) {
                if(phase == PhaseMorning) {
                    [self afternoonStart];
                }
            }
        }
        
        //ペリフェラルからのゲーム終了通知「gameEnd:W」Wは処理者チームID (utilityを参照）
        if([[BWUtility getCommand:message] isEqualToString:@"gameEnd"]) {
            winner = [[BWUtility getCommandContents:message][0]integerValue];
            [self gameEnd];
        }
    } else {
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
            
            //ログを送信
            if([sendManager isPeripheral]) {
                NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
                NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
                NSString *name = infoDic[@"players"][playerId][@"name"];
                [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"%d/-/%@/-/%@",(int)roleId,name,text]];
            }
            
            NSArray *shouldSendIds = [self getSameChatroomMemberId:identificationId];
            for(NSInteger i=0;i<shouldSendIds.count;i++) {
                NSString *mes = [NSString stringWithFormat:@"chatreceive:%@/%@",identificationId,text];
                [sendManager sendMessageWithAddressId:mes toId:shouldSendIds[i]];
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
                [self morning];
            }
        }
        
        //セントラルによる犠牲者確認通知「checkVictim:A..A」
        if([[BWUtility getCommand:message] isEqualToString:@"checkVictim"]) {
            NSString *identificationId = [BWUtility getCommandContents:message][0];
            NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
            checkList[playerId] = @YES;
            if([self isAllOkCheckList]) {
                [self afternoonStart];
            }
        }
        
        //セントラルによる・夜直前の道連れ確認通知「afternoonVictimCheck:C..C」
        if([[BWUtility getCommand:message] isEqualToString:@"afternoonVictimCheck"]) {
            NSString *identificationId = [BWUtility getCommandContents:message][0];
            NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
            checkList[playerId] = @YES;
            if([self isAllOkCheckList]) {
                [self nightStart];
            }
        }
        
        //セントラルによる投票結果確認通知「checkVoting:A..A」
        if([[BWUtility getCommand:message] isEqualToString:@"checkVoting"]) {
            NSString *identificationId = [BWUtility getCommandContents:message][0];
            NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
            checkList[playerId] = @YES;
            if([self isAllOkCheckList]) {
                if(excutionerId == -1) {
                    //再投票
                    votingArray = [NSMutableArray array];
                    voteCount++;
                    [sendManager sendMessageForAllCentrals:@"nightStart:"];
                  
                    [self finishAfternoon];
                } else {
                    [self nightStart];
                }
            }
        }
    }
}



-(NSArray*)divideMessage :(NSString*)message {
    NSInteger limit = 80;
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
                [sendManager sendMessageWithAddressId:mes toId:shouldSendIds[i]];
               
            }
            
            //ログを送信
            if([sendManager isPeripheral]) {
                NSInteger playerId = [BWUtility getMyPlayerId:infoDic];
                NSInteger roleId = [infoDic[@"players"][playerId][@"roleId"]integerValue];
                NSString *name = infoDic[@"players"][playerId][@"name"];
                [[LWBonjourManager sharedManager] sendData:[NSString stringWithFormat:@"%d/-/%@/-/%@",(int)roleId,name,array[j]]];
            }
            
        } else {
            //まずはペリフェラルに知らせる
            NSString *mes = [NSString stringWithFormat:@"chatsend:%@/%@",[BWUtility getIdentificationString],array[j]];
            [sendManager sendMessageForPeripheral:mes];

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
    
    int afternoonTime = [infoDic[@"rules"][@"timer"]intValue] * minuteSeconds;
    if(seconds == (int)(afternoonTime*0.9)  && phase == PhaseAfternoon) {
        [self backgroundMorphing:[SKTexture textureWithImageNamed:@"evening.jpg"] time:afternoonTime*0.9];
    }
}

#pragma mark - tableDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableMode == TableModeVoteResult) {
        return votingArray.count;
    }
    return tableArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableMode == TableModeVoteResult) {
        BWVoteCell *cell = [tableView dequeueReusableCellWithIdentifier:@"votecell"];
        
        NSString *voterString = infoDic[@"players"][[votingArray[indexPath.row][@"voter"]integerValue]][@"name"];
        NSString *votedString = infoDic[@"players"][[votingArray[indexPath.row][@"voteder"]integerValue]][@"name"];
        NSInteger count = [votingArray[indexPath.row][@"count"]integerValue];
        
        if(!cell) {
            cell = (BWVoteCell*)[[BWVoteCell alloc]init];
            
            [cell setVoterString:voterString votedString:votedString count:count cellSize:CGSizeMake(table.tableView.frame.size.width, table.tableView.frame.size.width/1446*244)];
        }
        cell.voter.text = voterString;
        cell.voteder.text = votedString;
        cell.counter.text = [NSString stringWithFormat:@"%d票",(int)count];
        return cell;
    }
    
    UITableViewCell *cell;
    
    //if(tableMode == TableModeNormal) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (!cell) {
            cell = [BWGorgeousTableView makePlateCellWithReuseIdentifier:@"cell" colorId:0];
            //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
        }
        
        NSString *name = tableArray[indexPath.row][@"name"];
        
        cell.textLabel.text = name;
       // return cell;
    //}
    
    
    if(tableRoleId == RoleBodyguard && ![infoDic[@"rules"][@"canContinuousGuard"]boolValue] && lastNightGuardIndex != -1) {
        NSString *targetIdentificationId = tableArray[indexPath.row][@"identificationId"];
        targetIndex = [BWUtility getPlayerId:infoDic id:targetIdentificationId];
        if(targetIndex == lastNightGuardIndex) {
            cell.detailTextLabel.text = @"連続護衛禁止";
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    //TODO::テーブルタッチ操作
    NSString *targetIdentificationId = tableArray[indexPath.row][@"identificationId"];
    targetIndex = [BWUtility getPlayerId:infoDic id:targetIdentificationId];
    
    //連続護衛禁止
    if(tableRoleId == RoleBodyguard && lastNightGuardIndex == targetIndex && ![infoDic[@"rules"][@"canContinuousGuard"]boolValue]) {
        return;
    }
    
    NSString *message = @"";
    if(tableRoleId == RoleWerewolf) {
        message = [NSString stringWithFormat:@"「%@」さんを噛みますか？",infoDic[@"players"][targetIndex][@"name"]];
    }
    if(tableRoleId == RoleFortuneTeller) {
        message = [NSString stringWithFormat:@"「%@」さんを占いますか？",infoDic[@"players"][targetIndex][@"name"]];
    }
    if(tableRoleId == RoleBodyguard) {
        message = [NSString stringWithFormat:@"「%@」さんを守りますか？",infoDic[@"players"][targetIndex][@"name"]];
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
    
    if(tableMode == TableModeVoteResult) {
        label.textColor = [UIColor blackColor];
        if(excutionerId == -1) {
            label.text = [NSString stringWithFormat:@"%d日目%d回目投票結果\r\n同票のため再投票します。（あと%d回)",(int)day,(int)voteCount,(int)voteMaxCount-(int)voteCount];
        } else {
            label.text = [NSString stringWithFormat:@"%d日目%d回目投票結果\r\n「%@」さんが追放されました。",(int)day,(int)voteCount,infoDic[@"players"][excutionerId][@"name"]];
        }
        label.numberOfLines = 2;
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor groupTableViewBackgroundColor];
        return label;
    }
    
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
    if(tableMode == TableModeVoteResult) {
        return 100.0;
    }
    return 30;
}

@end
