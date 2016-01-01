//
//  BWGameSettingScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "BWGameSettingScene.h"
#import "BWPeripheralManager.h"
#import "BWUtility.h"
#import "NSObject+BlocksWait.h"

@interface BWGameSettingScene () {
    BWPeripheralManager *manager;
    
    NSInteger gameId;
    
    UITableView *tableView;
    NSMutableArray *registeredPlayersArray;
}

@end

@implementation BWGameSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    gameId = [BWUtility getRandInteger:1000000];
    
    manager = [BWPeripheralManager sharedInstance];
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    self.backgroundColor = [UIColor blueColor];
    
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc]initWithImageNamed:@"afternoon.jpg"];
    backgroundNode.size = CGSizeMake(self.size.width, self.size.height);
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:backgroundNode];
    
    
    SKLabelNode *title = [[SKLabelNode alloc]init];
    title.fontSize = self.size.height*0.05;
    title.text = [NSString stringWithFormat:@"プレイヤー登録画面"];
    SKLabelNode *title2 = [[SKLabelNode alloc]init];
    title2.fontSize = self.size.height*0.05;
    title2.text = [NSString stringWithFormat:@"ゲームID:%06ld",(long)gameId];
    title2.fontName = @"HiraKakuProN-W3";
    
    
    title.position = CGPointMake(0, self.size.height*0.4);
    title2.position = CGPointMake(0, self.size.height*0.3);
    [backgroundNode addChild:title];
    [backgroundNode addChild:title2];
    
    [NSObject performBlock:^{
        [[BWPeripheralManager sharedInstance] updateSendMessage:[NSString stringWithFormat:@"receive:%06ld",(long)gameId]];
        [NSObject performBlock:^{
            [[BWPeripheralManager sharedInstance] updateSendMessage:[NSString stringWithFormat:@"receive:%06ld",(long)gameId]];
            [NSObject performBlock:^{
                [[BWPeripheralManager sharedInstance] updateSendMessage:[NSString stringWithFormat:@"receive:%06ld",(long)gameId]];
                [NSObject performBlock:^{
                    [[BWPeripheralManager sharedInstance] updateSendMessage:[NSString stringWithFormat:@"receive:%06ld",(long)gameId]];
                    [NSObject performBlock:^{
                        [[BWPeripheralManager sharedInstance] updateSendMessage:[NSString stringWithFormat:@"receive:%06ld",(long)gameId]];
                    } afterDelay:5.0];
                } afterDelay:5.0];
            } afterDelay:5.0];
        } afterDelay:5.0];
    } afterDelay:5.0];
    
    
}
/*
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
 */

@end
