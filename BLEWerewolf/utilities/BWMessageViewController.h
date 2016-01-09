//
//  BWMessageViewController.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/03.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import <JSQMessagesViewController/JSQMessages.h>

@protocol BWMessageViewControllerDelegate
-(void)didSendChat:(NSString*)message;
@end

@interface BWMessageViewController : JSQMessagesViewController {
    id<BWMessageViewControllerDelegate> _delegate;
}

@property (nonatomic) id<BWMessageViewControllerDelegate> delegate;

+ (instancetype)sharedInstance:(NSMutableDictionary*)infoDic;

-(BOOL)isMember:(NSString*)id;

-(void)receiveMessage:(NSString*)text id:(NSString*)identificationId infoDic:(NSMutableDictionary*)infoDic;

-(NSString*)getGmId;
@end
