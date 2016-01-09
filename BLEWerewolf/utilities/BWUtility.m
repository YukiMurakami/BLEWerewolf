//
//  BWUtility.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWUtility.h"
#import "BWMultipleLineLabelNode.h"


@implementation BWUtility

+(SKSpriteNode *) makeButton :(NSString*) text
                         size:(CGSize)size
                         name:(NSString*)name
                     position:(CGPoint)position
{
    SKSpriteNode *button = [[SKSpriteNode alloc]initWithImageNamed:@"button.png"];
    button.size = size;
    button.position = position;
    button.name = name;
    SKLabelNode *buttonLabel = [[SKLabelNode alloc]init];
    buttonLabel.text = text;
    buttonLabel.fontSize = button.size.height*0.5;
    buttonLabel.fontName = @"HiraKakuProN-W3";
    buttonLabel.fontColor = [UIColor blackColor];
    buttonLabel.position = CGPointMake(0, -button.size.height*0.20);
    buttonLabel.name = name;
    [button addChild:buttonLabel];
    
    return button;
}

+ (NSInteger)getRandInteger :(NSInteger)maxInteger {
    return (NSInteger)arc4random_uniform((int)maxInteger);
}

+ (NSString*)getRandomString :(NSInteger)digit {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    uint8_t length = [letters length];
    char data[(int)digit];
    for (int x=0;x<digit;data[x++] = [letters characterAtIndex:arc4random_uniform(length)]);
    return [[NSString alloc] initWithBytes:data length:digit encoding:NSUTF8StringEncoding];
}

#pragma mark - role
+(NSMutableArray *) getDefaultRoleArray :(int) count {
    //0村1狼2占 3霊4狂5ボ 6共7狐
    NSMutableArray *result = [@[@[@0,@0,@0,@0,@0,@0,@0,@0],//0
                                @[@1,@0,@0,@0,@0,@0,@0,@0],//1
                                @[@2,@0,@0,@0,@0,@0,@0,@0],
                                @[@2,@1,@0,@0,@0,@0,@0,@0],
                                @[@3,@1,@0,@0,@0,@0,@0,@0],
                                @[@3,@1,@1,@0,@0,@0,@0,@0],//5
                                @[@4,@1,@1,@0,@0,@0,@0,@0],
                                @[@5,@1,@1,@0,@0,@0,@0,@0],
                                @[@5,@2,@1,@0,@0,@0,@0,@0],
                                @[@5,@2,@1,@1,@0,@0,@0,@0],
                                @[@5,@2,@1,@1,@1,@0,@0,@0],//10
                                @[@5,@2,@1,@1,@1,@1,@0,@0],
                                @[@6,@2,@1,@1,@1,@1,@0,@0],
                                @[@5,@2,@1,@1,@1,@1,@2,@0],
                                @[@5,@2,@1,@1,@1,@1,@2,@1],
                                @[@6,@2,@1,@1,@1,@1,@2,@1],//15
                                @[@6,@3,@1,@1,@1,@1,@2,@1],
                                @[@7,@3,@1,@1,@1,@1,@2,@1],
                                @[@8,@3,@1,@1,@1,@1,@2,@1],
                                @[@9,@3,@1,@1,@1,@1,@2,@1],
                                @[@9,@4,@1,@1,@1,@1,@2,@1],//20
                                @[@10,@4,@1,@1,@1,@1,@2,@1],
                                @[@11,@4,@1,@1,@1,@1,@2,@1],
                                @[@11,@4,@1,@1,@1,@1,@2,@2],
                                @[@12,@4,@1,@1,@1,@1,@2,@2],
                                @[@12,@5,@1,@1,@1,@1,@2,@2],//25
                                @[@13,@5,@1,@1,@1,@1,@2,@2],
                                @[@14,@5,@1,@1,@1,@1,@2,@2],
                                @[@13,@5,@1,@1,@2,@1,@3,@2],
                                @[@13,@6,@1,@1,@2,@1,@3,@2],
                                @[@12,@7,@1,@1,@2,@2,@3,@2],//30
                                ] mutableCopy];
    for(NSInteger i=0;i<31;i++) {
        result[i] = [result[i]mutableCopy];
        for(NSInteger j=0;j<[self getMaxRoleCount]-8;j++) {
            [result[i] addObject:@(0)];
        }
    }
    return result[count];
}

+(int) getMaxRoleCount {
    //TODO::役職追加時変更点
    return 8;
}

+(NSMutableDictionary *) getCardInfofromId :(int) cardId {
    NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
    
    NSString *name = @"name";
    NSString *token = @"";
    NSString *explain = @"explain";
    NSString *detailExplain = @"特になし";
    NSString *firstNightMessage = @"";
    bool hasTable = false;//夜のアクションでテーブルが必要か
    bool hasTableFirst = false;//初夜のアクションでテーブルが必要か
    NSString *tableString = @"";//夜のアクションでテーブルに表示される文字列
    NSString *tableStringFirst = @"";//初夜のアクションでテーブルに表示される文字列
    NSInteger maxPlayer = 1000;//各役職の最大数（参加プレイヤーに関係なく）を設定する
    NSUInteger surfaceRole = RoleVillager;//役職画面で表示される表向きの役職ID（通常はRoleIdと一致する）
    
    //分かりにくい詳細ルールはここにメモる
    //・猫又の呪い発動は、「襲撃、処刑」で死亡した場合のみ ok
    //・勝利条件優先度は　死神陣営＞妖狐陣営＞村人・人狼陣営 ok
    //・死亡判定は、朝になってから、夜を迎える前、の２点で行う。処刑や襲撃、その他要因で死亡者をリスト化しておき、まず死亡させる。その後に、例えば生存背徳者は狐の生存フラグを確認して、全滅していたら後追い自殺、という処理にする。 ok
    //・タフガイを２回噛んでも、２回目はそのままタフガイは死亡する。ok
    //・狩人の能力発動はいかなる理由で死亡した時でも起こる。ok
    //・死神が襲撃対象になった時は「襲撃なし」、猫又の処刑による道連れの場合は「だれも道連れになりませんでした」、死神処刑時は「〜さんは処刑できませんでした」、狩人の道連れは「〜さんは道連れにできませんでした」というメッセージを表示する。ok,o,o
    //・猫又に襲撃とデスノートによる死亡が同時発生した場合は、人狼の襲撃が優先され、デスノートは空打ちとする
    //・妖狐からは子狐・背徳者はわからない。 ok
    //・子狐からは妖狐はわかるが、背徳者はわからない ok
    //・背徳者からは妖狐も子狐もわかるが、内訳まではわからない（子狐がいる場合は、妖狐・子狐が全滅した場合に後追い自殺する) ok
    //・子狐は成功率70%の占いを行えるが、この占いで妖狐は呪殺できない。
    //・名探偵は推理披露ボタンを押しても、その夜に死亡したら推理できない。
    
    switch (cardId) {
            //roleIdはcellActionなど全て共通で用いられるが、予約語的な例外もある
        case RoleVillager:
            name = @"村人";//実装済み
            token = @"村";
            surfaceRole = RoleVillager;
            hasTable = false;
            explain = @"村人は特殊な能力を持たないただの人です。夜時間は考察を書きましょう。";
            firstNightMessage = @"あなたは「村人」です。夜時間は必ず考察を書き込んでください。誰が人狼か、誰が真の役職なのかなど推理してください。";
            break;
        case RoleWerewolf:
            name = @"人狼";//実装済み
            token = @"狼";
            surfaceRole = RoleWerewolf;
            hasTable = true;
            hasTableFirst = true;
            tableStringFirst = @"仲間の人狼を確認してください。";
            tableString = @"襲撃先を選択してください。";
            explain = @"人狼は毎晩仲間同士で相談し人間を一人噛むことができます。夜時間は狼専用チャットで相談し、代表者が襲撃先を選択します。";
            firstNightMessage = @"ここは「人狼専用チャット」です。仲間と相談できます。なお、夜時間終了までに代表者がアクションボタンから、襲撃先を決定してください。アクションが行われなかった場合はランダムに一名決定します。";
            break;
        case RoleFortuneTeller:
            name = @"占い師";//実装済み
            token = @"占";
            surfaceRole = RoleFortuneTeller;
            hasTable = true;
            tableString = @"占い先を選択してください。";
            explain = @"予言者は毎晩疑っている人物を１人指定してその人物が人狼かそうでないかを知ることができます。";
            firstNightMessage = @"あなたは「占い師」です。考察を書き込みつつ、夜時間中に占い作業を完了してください。";
            break;
        case RoleShaman:
            name = @"霊媒師";//実装済み
            token = @"霊";
            surfaceRole = RoleShaman;
            hasTable = false;
            explain = @"霊媒師は毎晩その日の昼のターンに処刑された人が人狼だったのかそうでなかったのかを知ることができます。";
            break;
        case RoleMadman:
            name = @"狂人";//実装済み
            token = @"狂";
            surfaceRole = RoleMadman;
            hasTable = false;
            explain = @"狂人は何も能力を持っていませんが、人狼が勝つと勝利します。";
            break;
        case RoleBodyguard:
            name = @"ボディーガード";//実装済み
            token = @"狩";
            surfaceRole = RoleBodyguard;
            hasTable = true;
            tableString = @"護衛先を選択してください。";
            explain = @"ボディーガードは毎晩誰かを一人指定してその人物を人狼の襲撃から守ります。ただし、自分自身を守ることはできません。";
            break;
        case RoleJointOwner:
            name = @"共有者";//実装済み
            token = @"共";
            surfaceRole = RoleJointOwner;
            hasTable = false;
            hasTableFirst = true;
            tableStringFirst = @"共有者を確認してください。";
            explain = @"共有者は必ず複数人で一組として存在し、お互いに相手を確認できます。夜時間には共有者専用チャットを使用できます。";
            break;
        case RoleFox:
            name = @"妖狐";//実装済み
            token = @"狐";
            surfaceRole = RoleFox;
            hasTableFirst = true;
            tableStringFirst = @"仲間の妖狐を確認してください。";
            hasTable = false;
            explain = @"妖狐は第３の勢力です。ゲームが終了した時に妖狐が生き残っていれば勝利します。妖狐同士は夜時間に専用チャットを使用できます。";
            break;
            /*
        case RolePossessed:
            name = @"狼憑き";//実装済み
            surfaceRole = RoleVillager;
            hasTable = false;
            explain = @"狼憑きは特殊な能力を持たない村人側の人間です。しかし予言者があなたの正体を見たとき、あなたは人間であるにも関わらず人狼として判定されてしまいます。しかも、あなたは自分のことを村人だと思っています。";
            detailExplain = @"ちなみに霊媒結果は人間となる。";
            break;
        case RoleToughGuy:
            name = @"タフガイ";//実装済み
            surfaceRole = RoleToughGuy;
            hasTable = false;
            explain = @"タフガイは人狼の襲撃にあってもすぐには死にません。１日の間は生き延び、翌日の夜死亡します。ただし昼の処刑では普通に殺されてしまいます。夜に犠牲者がいなかった場合、あなたが襲撃されてしまった可能性があるのです。";
            break;
        case RoleApprenticeFortuneTeller:
            name = @"見習い予言者";//実装済み
            surfaceRole = RoleApprenticeFortuneTeller;
            hasTable = false;
            explain = @"見習い予言者はゲーム開始時には特殊な能力を持っていません。しかし、夜が来たときに予言者がすでにいない場合、その夜から覚醒して新たな予言者となります。";
            break;
        case RoleWolfboy:
            name = @"狼少年(未実装)";
            surfaceRole = RoleWolfboy;
            hasTable = true;
            tableString = @"狼の皮をかぶせる先を選択してください。";
            hasTableFirst = true;
            tableStringFirst = @"狼の皮をかぶせる先を選択してください。";
            explain = @"狼少年は毎晩好きな人物を１人指定して、その人物が予言者に見られた時の判定をその晩の間だけ人狼に変えてしまいます。霊媒師など予言者以外の役職の判定には影響を及ぼしません。";
            break;
        case RoleTrapmaker:
            name = @"罠師(未実装)";
            surfaceRole = RoleTrapmaker;
            hasTable = true;
            tableString = @"罠の仕掛け先を選択してください。";
            explain = @"";
            break;
        case RoleCursed:
            name = @"呪われた者";//実装済み
            surfaceRole = RoleVillager;
            hasTable = false;
            explain = @"ゲーム開始時は能力のない村人ですが、夜に人狼に襲撃された場合、あなたは死亡せずに生き残り、翌日の夜に新たな人狼として目覚めます。それ以降は人狼チームとして勝利を目指しましょう。なお、襲撃されるまではあなたは村人だと思っています。";
            detailExplain = @"呪われたものが襲撃された次の昼に人狼が全滅しても、その夜から呪われたものがラストウルフ(LW)としてゲームは続行する。";
            break;
        case RoleKing:
            name = @"王様(未実装)";
            surfaceRole = RoleKing;
            hasTable = false;
            explain = @"";
            break;
        case RoleDictator:
            name = @"独裁者(未実装)";
            surfaceRole = RoleDictator;
            hasTable = false;
            explain = @"独裁者は昼の議論中に、独裁者ボタンを押すことによって一度だけ議論を強制的に終了させ、処刑者を選択することができます。他のプレイヤーは騙りでの独裁者COは禁止です。";
            maxPlayer = 1;
            break;
        case RoleMotherFortuneTeller:
            name = @"予言者のママ";//実装済み
            surfaceRole = RoleMotherFortuneTeller;
            hasTableFirst = true;
            tableStringFirst = @"予言者を確認してください。";
            hasTable = false;
            explain = @"予言者のママははじめの夜に目を覚まし、誰が予言者なのか知ることができます。予言者が複数名乗り出たときは誰が本物か証明してあげましょう。";
            break;
        case RoleHunter:
            name = @"狩人";//実装済み
            surfaceRole = RoleHunter;
            hasTable = false;
            tableString = @"道連れにする人を選択してください。";
            explain = @"狩人は自らが死亡した際に役職が公開され、その時点での生存者を一人指名しその人物を道連れにして死亡させます。人狼を仕留められるかもしれませんが、罪のない人間を殺してしまうかもしれないハイリスク・ハイリターンな役職です。";
            detailExplain = @"猫又とは異なり、いかなる理由で死亡しても能力が強制的に発動する。";
            break;
        case RoleMiming:
            name = @"ものまね師";//実装済み
            surfaceRole = RoleMiming;
            hasTable = false;
            explain = @"ものまね師自身は能力を持たないただの人間ですが、あなたはゲーム中に必ず何らかの役職を演じなければなりません。またゲーム中に自分がものまね師だと宣言してもいけません。うまく人狼だけを騙しましょう。";
            break;
        case RoleFanatic:
            name = @"狂信者";//実装済み
            surfaceRole = RoleFanatic;
            hasTableFirst = true;
            tableStringFirst = @"人狼を確認してください。";
            hasTable = false;
            explain = @"狂信者は何も能力を持っていませんが、人狼側の人間です。人狼が勝利した時、自らも勝者となります。予言者に見られてもただの人間と判定されます。ただし初日の夜に誰が人狼であるかを知ることができる人狼の強力な味方です。";
            detailExplain = @"誰が狼かはわかりますが、大狼がいる場合、それを区別することはできません。";
            break;
        case RoleImmoralist:
            name = @"背徳者";//実装済み
            surfaceRole = RoleImmoralist;
            hasTableFirst = true;
            tableStringFirst = @"妖狐を確認してください。";
            hasTable = false;
            explain = @"背徳者は村人とほとんど同じですが、村人にも人狼にも属さない第３の勢力です。ゲームが終了した時に妖狐が生き残っていれば、妖狐陣営として勝利します。背徳者は「妖狐」が誰かを知ることができ、妖狐が死亡・殺害されて全滅した際、後を追って死亡します。その場合、後追い自殺として表示されます。";
            break;
        case RoleCat:
            name = @"猫又";//実装済み
            surfaceRole = RoleCat;
            hasTableFirst = false;
            hasTable = false;
            explain = @"猫又は村人陣営です。猫又は昼の会議で処刑された場合、生存者の中からランダムで一人を道連れに死亡させます。しかし夜に人狼に噛まれた場合は、最も強く噛んできた人狼を１匹道連れにすることができます。頑張って人狼に噛まれるよう振舞いましょう。";
            detailExplain = @"猫又の呪いは、処刑時は夜を迎える前に発動し、「〜さんは猫又の呪いで死亡しました」というメッセージが出る。逆に襲撃時は翌朝「昨日の犠牲者は〜さんと〜さんでした」というように犠牲者メッセージで表示される。つまりどちらが人狼であったかは区別できない。また猫又は、別の猫又や狩人の道連れなど、「処刑」「襲撃」以外では呪いが発動しない。";
            break;
        case RoleBaker:
            name = @"パン屋";//実装済み
            surfaceRole = RoleBaker;
            hasTableFirst = false;
            hasTable = false;
            explain = @"パン屋は村人陣営です。朝になった時にパン屋が生存していれば、「今日もパン屋が美味しいパンを焼いてくれました。」と表示されます。朝になったときにパン屋が死亡していた場合は、「今日からは美味しいパンが食べれなくなります。」と表示されます。";
            break;
        case RoleNoble:
            name = @"貴族";//実装済み
            surfaceRole = RoleNoble;
            hasTableFirst = false;
            hasTable = false;
            explain = @"貴族は村人陣営です。あなたは人狼に襲撃された場合でも、奴隷が生存していれば身代わりに死亡してくれます。奴隷からは貴族が誰であるかわかりますが、あなたからは奴隷が誰であるかはわかりません。また貴族は初日には死亡しません。";
            break;
        case RoleSlave:
            name = @"奴隷";//実装済み
            surfaceRole = RoleSlave;
            hasTableFirst = true;
            tableStringFirst = @"貴族を確認してください。";
            hasTable = false;
            explain = @"奴隷は村人陣営です。村人陣営の勝利かつ貴族の死亡が勝利条件です。あなたが生存している時に、貴族が人狼に襲撃された場合身代わりに死亡します。奴隷からは貴族が誰であるかわかりますが、貴族からは奴隷が誰であるかはわかりません。";
            break;
        case RoleCupid:
            name = @"キューピッド（未実装）";
            surfaceRole = RoleCupid;
            hasTableFirst = true;
            tableStringFirst = @"恋人にする二人を選んでください。";
            hasTable = false;
            explain = @"キューピッドは恋人陣営です。あなたの選んだ恋人がゲーム終了まで生き残っていたら、恋人陣営の単独勝利です。あなたの生死は勝利条件に含まれません。恋人は片方が死んでしまうと残された方は後を追って自殺します。うまく恋人が生き残れるように振舞いましょう。自分を恋人に選ぶこともできます。";
            maxPlayer = 1;
            break;
        case RoleBossWerewolf:
            name = @"大狼";//実装済み
            surfaceRole = RoleBossWerewolf;
            hasTable = true;
            hasTableFirst = true;
            tableStringFirst = @"仲間の人狼を確認してください。";
            tableString = @"襲撃先を選択してください。";
            explain = @"人狼は毎晩目を覚まし、村の人間を一人ずつ選んで喰い殺していきます。人狼同士で協力して人間を喰い尽くし、村を全滅させてしまいましょう。大狼は占われても「人間」と判定されますが、霊媒結果では「大狼」と判定されます。";
            break;
        case RoleGrimReaper:
            name = @"死神";//実装済み
            surfaceRole = RoleGrimReaper;
            hasTableFirst = true;
            tableStringFirst = @"デスノートを落とす人物を決めてください。";
            explain = @"死神は初日の夜にデスノートを誰かに落とします。拾った人物は役職に関わらず「キラ」となり、勝利条件が「死神とキラ以外の抹殺」に変更されます。死神はキラが死んだ場合は死亡しますが、それ以外の要因では決して死亡しません。";
            detailExplain = @"「キラ」は次の夜から毎晩ノートに「誰を何日目の夜に殺すか」を記入します。キラが死亡した場合の死神は「〜さんは下界に興味がなくなりデスノートを持って死神界へと帰って行きました。」という専用メッセージが即座に表示される。なお、他の陣営が勝利条件を満たしてもキラが生存している限りはゲームが続行します。またノートに記入された効果はキラ死亡後は効果を発動しません。";
            maxPlayer = 1;
            break;
        case RoleSmallFox:
            name = @"子狐";//実装済み
            surfaceRole = RoleSmallFox;
            hasTableFirst = true;
            hasTable = true;
            tableStringFirst = @"妖狐を確認してください。";
            tableString = @"占う人を選択してください。";
            explain = @"子狐は妖狐陣営です。あなたは占われても呪殺されず「人間」と判定されますが、霊媒結果では「子狐」と判定されます。またあなたは70%成功率の占い能力を持っています。占い失敗の場合は「占い失敗」と表示されます。子狐の占いでは妖狐は呪殺されません。あなたは妖狐が誰かはわかりますが、妖狐はあなたを知りません。";
            detailExplain = @"背徳者は妖狐、子狐（内訳不明）がわかる。子狐は子狐と妖狐（内訳不明）がわかる。妖狐は妖狐しかわからない。子狐は狼に噛まれたら死亡し、占われても呪殺されない。ただし、子狐の占いでは妖狐は呪殺されない。";
            break;
            //TODO::役職追加時変更点
        case RoleDetective:
            name = @"名探偵";
            surfaceRole = RoleDetective;
            explain = @"名探偵は第３陣営（名探偵陣営）です。あなたは夜のうちに翌朝推理ショーをするかどうか選択します。その推理ショーで「占い師」「霊媒師」「ボディーガード」「人狼すべて」を言い当てることができればその瞬間単独勝利します。ただ、推理を外したら恥ずかしさのあまり自殺します。";
            detailExplain = @"推理ショーをすることを選択しても、その日の夜に死亡してしまった場合はそのまま敗北します。人狼を当てる場合は「大狼」も当てないといけませんが、内訳までは当てる必要はありません。";
            maxPlayer = 1;
            break;
             */
        default:
            break;
    }
    
    infoDic = [@{@"name":name,@"explain":explain,@"hasTable":@(hasTable),@"tableString":tableString,
                 @"hasTableFirst":@(hasTableFirst),@"tableStringFirst":tableStringFirst,@"maxPlayer":@(maxPlayer),@"surfaceRole":@(surfaceRole),@"token":token,@"firstNightMessage":firstNightMessage} mutableCopy];
    
    return infoDic;
}

+(NSString*)getRoleSetString:(NSMutableArray*)roles {
    NSString *result = @"";
    for(NSInteger i=0;i<roles.count;i++) {
        if([roles[i]integerValue] > 0) {
            result = [NSString stringWithFormat:@"%@%@%@",result,[BWUtility getCardInfofromId:i][@"token"],roles[i]];
        }
    }
    return result;
}

+(SKTexture *) getCardTexture :(int) cardId {
    NSLog(@"getTexture:filename[%@]",[NSString stringWithFormat:@"card%d.png",cardId]);
    NSString *filename = [NSString stringWithFormat:@"card%d.png",cardId];
    SKTexture *texture = [SKTexture textureWithRect:CGRectMake(0,0,1,1/*0.03,0.2,0.94,0.8*/) inTexture:[SKTexture textureWithImageNamed:filename]];
    return texture;
}

+ (NSString*)getFortuneButtonString :(FortuneTellerMode)mode {
    if(mode == FortuneTellerModeFree) return @"初日占い：あり";
    if(mode == FortuneTellerModeNone) return @"初日占い：なし";
    if(mode == FortuneTellerModeRevelation) return @"初日占い：お告げ";
    return @"";
}

+(NSMutableArray*) getRandomArray :(NSMutableArray*)array {
    NSMutableArray *result = [NSMutableArray array];
    
    int count = (int)array.count;
    
    for(int i=0;i<count*1000;i++) {
        int f1 = (int) arc4random_uniform(count);
        int f2 = (int) arc4random_uniform(count);
        
        id object = array[f1];
        array[f1] = array[f2];
        array[f2] = object;
    }
    
    for(int i=0;i<count;i++) {
        [result addObject:array[i]];
    }
    
    return result;
}

+(NSInteger)getMyPlayerId:(NSMutableDictionary*)infoDic {
    NSInteger id = -1;
    NSString *identificationString = [BWUtility getIdentificationString];
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        if([infoDic[@"players"][i][@"identificationId"] isEqualToString:identificationString]) {
            id = i;
            break;
        }
    }
    return id;
}

+(Role)getMyRoleId:(NSMutableDictionary*)infoDic {
    NSInteger myPlayerId = [BWUtility getMyPlayerId:infoDic];
    Role roleId = (Role)[infoDic[@"players"][myPlayerId][@"roleId"]integerValue];
    return roleId;
}

+(NSInteger)getPlayerId:(NSMutableDictionary*)infoDic id:(NSString*)identificationId {
    NSInteger id = -1;
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        if([infoDic[@"players"][i][@"identificationId"] isEqualToString:identificationId]) {
            id = i;
            break;
        }
    }
    return id;
}


#pragma mark - ui

+(SKSpriteNode *) makeFrameNode :(CGSize)size position:(CGPoint)position color:(UIColor*)color texture:(SKTexture *)texture {
    SKSpriteNode *explain = [[SKSpriteNode alloc]initWithImageNamed:@"frame.png"];
    explain.size = size;
    explain.position = position;
    SKSpriteNode *content = [[SKSpriteNode alloc]init];
    content.size = CGSizeMake(explain.size.width*0.9,explain.size.height*0.92);
    content.position = CGPointMake(0,0);
    if(!texture) {
        content.color = color;
        content.colorBlendFactor = 1.0;
    } else {
        content.texture = texture;
    }
    [explain addChild:content];
    
    return explain;
}

+(SKSpriteNode *) makeMessageNode :(CGSize)frameSize position:(CGPoint)position backColor:(UIColor*)color string:(NSString*)string fontSize:(CGFloat)fontSize fontColor:(UIColor*)fontColor {
    SKSpriteNode *explain = [BWUtility makeFrameNode:frameSize position:position color:color texture:nil];
    BWMultipleLineLabelNode *explainLabel = [[BWMultipleLineLabelNode alloc]init];
    explainLabel.size = CGSizeMake(explain.size.width*0.8,explain.size.height*0.8);
    [explainLabel setText:string fontSize:fontSize fontColor:fontColor];
    [explain addChild:explainLabel];
    return explain;
}

+(SKSpriteNode *) makeMessageAndImageNode :(CGSize)messageSize position:(CGPoint)messagePosition color:(UIColor*)backColor string:(NSString*)message fontSize:(CGFloat)fontSize fontColor:(UIColor*)fontColor imageTexture:(SKTexture*)texture imageWidthRate:(CGFloat)imageWidthRate isRotateRight:(BOOL)isRotateRight {
    
    SKSpriteNode *explain = [BWUtility makeFrameNode:messageSize position:messagePosition color:backColor texture:nil];
    CGSize imageSizeA = CGSizeMake(messageSize.width*imageWidthRate/5*6, messageSize.width*imageWidthRate);
    CGSize imageSize = imageSizeA;
    if(!isRotateRight) {
        imageSize = CGSizeMake(imageSizeA.height, imageSizeA.width);
    }
    if(isRotateRight) {
        SKSpriteNode *explain2 = [[SKSpriteNode alloc]initWithTexture:texture];
        explain2.size = imageSize;
        explain2.position = CGPointMake(0,messageSize.height/2*0.88 - imageSize.width/2);
        explain2.zRotation = -1.57;
        [explain addChild:explain2];
        BWMultipleLineLabelNode *explainLabel = [[BWMultipleLineLabelNode alloc]init];
        explainLabel.size = CGSizeMake(explain.size.width*0.8,messageSize.height*0.88 - imageSize.width);
        [explainLabel setText:message fontSize:fontSize fontColor:fontColor];
        explainLabel.position = CGPointMake(0,-messageSize.height*0.88/2 + explainLabel.size.height/2);
        [explain addChild:explainLabel];
    } else {
        SKSpriteNode *explain2 = [[SKSpriteNode alloc]initWithTexture:texture];
        explain2.size = imageSize;
        explain2.position = CGPointMake(0,messageSize.height/2*0.88 - imageSize.width/2);
        explain2.zRotation = 0.0;
        [explain addChild:explain2];
        BWMultipleLineLabelNode *explainLabel = [[BWMultipleLineLabelNode alloc]init];
        explainLabel.size = CGSizeMake(explain.size.width*0.8,messageSize.height*0.88 - imageSize.height);
        [explainLabel setText:message fontSize:fontSize fontColor:fontColor];
        explainLabel.position = CGPointMake(0,-messageSize.height*0.88/2 + explainLabel.size.height/2);
        [explain addChild:explainLabel];
    }
    
    return explain;
}

#pragma mark - data

//userdefault
//identificationString NSString : 端末別識別番号（初回起動時にUUIDと一切関係なくランダムに生成される）
//userData NSMutableDictionary : ユーザデータ情報

+ (NSString*)getIdentificationString {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *identificationString = [ud stringForKey:@"identificationString"];
    if(!identificationString) {
        identificationString = [BWUtility getRandomString:6];
        [ud setObject:identificationString forKey:@"identificationString"];
    }
    return identificationString;
}

+ (BOOL)wasSetting {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userData = [ud objectForKey:@"userData"];
    if(!userData) return NO;
    return YES;
}

+ (NSString*)getUserName {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userData = [ud objectForKey:@"userData"];
    if(!userData) return @"no_name";
    return userData[@"name"];
}


#pragma mark - string
+(NSString*)getCommand :(NSString*)command {
    NSString *result = @"";
    NSArray *array = [command componentsSeparatedByString:@":"];
    if(array.count >= 1) {
        result = array[0];
    }
    return result;
}

+(NSArray*)getCommandContents:(NSString*)command {
    NSArray *array = [command componentsSeparatedByString:@":"];
    if(array.count >= 2) {
        NSArray *contents = [array[1] componentsSeparatedByString:@"/"];
        return contents;
    }
    return @[];
}

@end
