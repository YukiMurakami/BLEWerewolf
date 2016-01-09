//
//  BWMessageViewController.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWMessageViewController.h"
#import "BWUtility.h"
#import "UIColor+BWAddtions.h"

NSString *gmId = @"aaaaaa";

@interface BWMessageViewController () {
    NSMutableDictionary *copyInfoDic;
}

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubble;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubble;
@property (strong, nonatomic) JSQMessagesBubbleImage *gmBubble;
@property (strong, nonatomic) JSQMessagesAvatarImage *gmAvatar;
@property (strong, nonatomic) NSMutableArray *playerAvatars;
@property (strong, nonatomic) NSMutableArray *membersId;//グループメンバ

@end

@implementation BWMessageViewController
@synthesize delegate = _delegate;

#pragma mark - Singleton
+ (instancetype)sharedInstance:(NSMutableDictionary*)infoDic
{
    static BWMessageViewController *sharedInstance = nil;
    
    static dispatch_once_t once;
    dispatch_once( &once, ^{
        sharedInstance = [[BWMessageViewController alloc] initSharedInstance:infoDic];
        
    });
    
    return sharedInstance;
}

- (id)initSharedInstance:(NSMutableDictionary*)infoDic {
    self = [super init];
    if (self) {
        // 初期化処理
        [self setMessageParams:infoDic];
    }
    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

-(void)setMessageParams:(NSMutableDictionary*)infoDic {
    // ① 自分の senderId, senderDisplayName を設定
    NSInteger myId = [BWUtility getMyPlayerId:infoDic];
    NSInteger myRoleId = [infoDic[@"players"][myId][@"roleId"]integerValue];
    self.senderId = infoDic[@"players"][myId][@"identificationId"];
    self.senderDisplayName = infoDic[@"players"][myId][@"name"];
    
    copyInfoDic = [infoDic mutableCopy];
    
    // ② MessageBubble (背景の吹き出し) を設定
    JSQMessagesBubbleImageFactory *bubbleFactory = [JSQMessagesBubbleImageFactory new];
    self.gmBubble = [bubbleFactory  incomingMessagesBubbleImageWithColor:[UIColor gmBubbleColor]];
    if(myRoleId == RoleWerewolf) {
        self.incomingBubble = [bubbleFactory  incomingMessagesBubbleImageWithColor:[UIColor werewolfPartnerBubbleColor]];
        self.outgoingBubble = [bubbleFactory  outgoingMessagesBubbleImageWithColor:[UIColor werewolfBubbleColor]];
    }
    if(myRoleId == RoleVillager) self.outgoingBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor villagerBubbleColor]];
    
    if(myRoleId == RoleFortuneTeller) self.outgoingBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor fortuneTellerBubbleColor]];
    if(myRoleId == RoleShaman) self.outgoingBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor shamanBubbleColor]];
    
    // ③ アバター画像を設定
    self.gmAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"gm.jpg"] diameter:64];
    //self.playerAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"player.jpg"] diameter:64];
    self.playerAvatars = [NSMutableArray array];
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        [self.playerAvatars addObject:[JSQMessagesAvatarImageFactory avatarImageWithUserInitials:infoDic[@"players"][i][@"name"] backgroundColor:[UIColor getPlayerColor:i] textColor:[UIColor blackColor] font:[UIFont fontWithName:@"HiraKakuProN-W6" size:self.view.frame.size.width*0.1*0.25] diameter:self.view.frame.size.width*0.1]];
    }
    
    self.membersId = [NSMutableArray array];
    [self.membersId addObject:gmId];//まずはGMをメンバに追加
    [self.membersId addObject:self.senderId];//自分をメンバに追加
    for(NSInteger i=0;i<[infoDic[@"players"] count];i++) {
        if(i == myId) continue;
        NSInteger targetRoleId = [infoDic[@"players"][i][@"roleId"]integerValue];
        if(myRoleId == RoleWerewolf) {//人狼チャットなら人狼を追加
            if(targetRoleId == RoleWerewolf) {
                [self.membersId addObject:infoDic[@"players"][i][@"identificationId"]];
            }
        }
    }
    
}

-(BOOL)isMember:(NSString*)id {
    BOOL isFind = NO;
    for(NSInteger i=0;i<self.membersId.count;i++) {
        if([self.membersId[i] isEqualToString:id]) {
            isFind = YES;
            break;
        }
    }
    return isFind;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // ④ メッセージデータの配列を初期化
    self.messages = [NSMutableArray array];
    
}

#pragma mark - JSQMessagesViewController

// ⑤ Sendボタンが押下されたときに呼ばれる
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    // 新しいメッセージデータを追加する
    JSQMessage *message = [JSQMessage messageWithSenderId:senderId
                                              displayName:senderDisplayName
                                                     text:text];
    [self.messages addObject:message];
    // メッセージの送信処理を完了する (画面上にメッセージが表示される)
    [self finishSendingMessageAnimated:YES];
    
    [_delegate didSendChat:text];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    [self hiddenKeyboard];
}

- (void)eraseKeyboard {
    [self hiddenKeyboard];
}

#pragma mark - JSQMessagesCollectionViewDataSource

// ④ アイテムごとに参照するメッセージデータを返す
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

// ② アイテムごとの MessageBubble (背景) を返す
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    if([message.senderId isEqualToString:gmId]) {
        return self.gmBubble;
    }
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubble;
    }
    return self.incomingBubble;
}

// ③ アイテムごとのアバター画像を返す
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:gmId]) {
        return self.gmAvatar;
    }
    
    NSInteger playerId = [BWUtility getPlayerId:copyInfoDic id:message.senderId];
    
    return self.playerAvatars[playerId];
}

#pragma mark - UICollectionViewDataSource

// ④ アイテムの総数を返す
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - receive

-(void)receiveMessage:(NSString*)text id:(NSString*)identificationId infoDic:(NSMutableDictionary*)infoDic {
    NSInteger playerId = [BWUtility getPlayerId:infoDic id:identificationId];
    NSString *name = @"";
    if([identificationId isEqualToString:gmId]) {
        name = @"GM";
    } else {
        name = infoDic[@"players"][playerId][@"name"];
    }
    
    JSQMessage *message = [JSQMessage messageWithSenderId:identificationId
                                              displayName:name
                                                     text:text];
    [self.messages addObject:message];
    // メッセージの受信処理を完了する (画面上にメッセージが表示される)
    [self finishReceivingMessageAnimated:YES];
}

-(NSString*)getGmId {
    return gmId;
}

@end
