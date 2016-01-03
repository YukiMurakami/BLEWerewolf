//
//  BWNightScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWNightScene.h"
#import "BWUtility.h"

@implementation BWNightScene

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
    
    CGFloat margin = self.size.height*0.05;
    CGFloat timerHeight = self.size.height*0.1;
    messageViewController = [BWMessageViewController sharedInstance:infoDic];
    messageViewController.view.frame = CGRectMake(margin, margin*2+timerHeight, self.size.width - margin*2, self.size.height - margin*3 - timerHeight);
    messageViewController.delegate = self;
    
    [self initBackground];
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"night.jpg"];
    [self addChild:backgroundNode];
    
    CGFloat margin = self.size.height*0.05;
    CGFloat timerHeight = self.size.height*0.1;
    
    SKSpriteNode *explain = [[SKSpriteNode alloc]initWithImageNamed:@"frame.png"];
    explain.size = CGSizeMake(timerHeight*218/307,timerHeight);
    explain.position = CGPointMake(-self.size.width/2+explain.size.width/2+margin,self.size.height/2-timerHeight/2-margin);
    SKSpriteNode *content = [[SKSpriteNode alloc]init];
    content.size = CGSizeMake(explain.size.width*0.9,explain.size.height*0.92);
    content.position = CGPointMake(0,0);
    content.texture = [BWUtility getCardTexture:[infoDic[@"players"][[BWUtility getMyPlayerId:infoDic]][@"roleId"]integerValue]];
    [explain addChild:content];
    [backgroundNode addChild:explain];
}

-(void)willMoveFromView:(SKView *)view {
    [messageViewController.view removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    [self.view addSubview:messageViewController.view];
}

-(void)didReceivedMessage:(NSString *)message {
    //central
    //ペリフェラルから受け取ったメッセージから、自分と同じグループチャットがあったら反映
    //ただし自分自信はすでに反映されているのでむし
    //chatreceive:A..A/T...T
    if([[BWUtility getCommand:message] isEqualToString:@"chatreceive"]) {
        NSArray *contents = [BWUtility getCommandContents:message];
        if([messageViewController isMember:contents[0]] && ![contents[0] isEqualToString:[BWUtility getIdentificationString]]) {
            //メッセージを反映
            NSString *text = @"";
            for(NSInteger i=1;i<contents.count;i++) {
                text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
            }
            [messageViewController receiveMessage:text id:contents[0] infoDic:infoDic];
        }
    }
}

-(void)didReceiveMessage:(NSString *)message {
    //peripheral
    //セントラルから受け取ったメッセージを全体に送信
    //その後自分と同じグループと同じグループチャットがあったら反映（ただし自分はむし）
    //chatsend:A..A/T...T
    if([[BWUtility getCommand:message] isEqualToString:@"chatsend"]) {
        NSArray *contents = [BWUtility getCommandContents:message];
        
        NSString *text = @"";
        for(NSInteger i=1;i<contents.count;i++) {
            text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
        }
        [peripheralManager updateSendMessage:[NSString stringWithFormat:@"chatreceive:%@/%@",contents[0],text]];
        
        if([messageViewController isMember:contents[0]] && ![contents[0] isEqualToString:[BWUtility getIdentificationString]]) {
            //メッセージを反映
            NSString *text = @"";
            for(NSInteger i=1;i<contents.count;i++) {
                text = [NSString stringWithFormat:@"%@%@",text,contents[i]];
            }
            [messageViewController receiveMessage:text id:contents[0] infoDic:infoDic];
        }
    }
}

#pragma mark - MessageViewControllerdelegate
-(void)didSendChat:(NSString *)message {
    //自分でチャットを送信すると呼ばれる
    //chatsend:A..A/T...T
    //chatreceive:A..A/T...T
    if(isPeripheral) {
        //外部に直接知らせる
        NSString *mes = [NSString stringWithFormat:@"chatreceive:%@/%@",[BWUtility getIdentificationString],message];
        [peripheralManager updateSendMessage:mes];
    } else {
        //まずはペリフェラルに知らせる
        NSString *mes = [NSString stringWithFormat:@"chatsend:%@/%@",[BWUtility getIdentificationString],message];
        [centralManager sendMessageFromClient:mes];
    }
}

@end
