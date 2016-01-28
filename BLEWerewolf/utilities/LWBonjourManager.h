//
//  LWBonjourManager.h
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2015/04/05.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LWBonjourManager : NSObject <NSStreamDelegate,NSNetServiceDelegate,NSNetServiceBrowserDelegate>{
    NSNetServiceBrowser* browser_;
    NSNetService *service_;
    NSInputStream *iStream_;
    NSOutputStream *oStream_;
}

+ (LWBonjourManager *)sharedManager;


- (void)searchNetService;
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void) sendData:(NSString *)sendString;


-(void)closeStream;

@end
