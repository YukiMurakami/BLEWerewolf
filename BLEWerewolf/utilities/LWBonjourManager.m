//
//  LWBonjourManager.m
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2015/04/05.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import "LWBonjourManager.h"

@interface LWBonjourManager ()  {
    
}

@end



@implementation LWBonjourManager

static LWBonjourManager *sharedData_ = nil;

//[[LWBonjourManager sharedManager] method];としてメソッドを呼び出す
+ (LWBonjourManager *)sharedManager{
    @synchronized(self){
        if (!sharedData_) {
            sharedData_ = [LWBonjourManager new];
        }
    }
    return sharedData_;
}

- (void)searchNetService
{
    browser_ = nil;
    browser_ = [[NSNetServiceBrowser alloc] init];
    browser_.delegate = self;
    [browser_ searchForServicesOfType:@"_test._tcp" inDomain:@""];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"%@", [aNetServiceBrowser description]);
    NSLog(@"%@", [aNetService description]);
    
    service_ = nil;
    
    service_ = [[NSNetService alloc] initWithDomain:[aNetService domain] type:[aNetService type] name:[aNetService name]];
    if (service_)
    {
        // connected
        service_.delegate = self;
        [service_ resolveWithTimeout:5.0f];
    }
    else
    {
        NSLog(@"connect failed.");
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"%@", [sender description]);
    NSInputStream *iStream = nil;
    NSOutputStream *oStream = nil;
    if (![sender getInputStream:&iStream outputStream:&oStream])
    {
        NSLog(@"cannot get streams");
        return;
    }
    
    oStream_ = oStream;
    
    
    if (oStream_)
    {
        [oStream_ open];
        [oStream_ scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

-(void)closeStream {
    [oStream_ close];
}

- (void) sendData:(NSString *)sendString
{
    if (oStream_)
    {
        NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"send:%@",sendString);
        
        [oStream_ write:[data bytes] maxLength:[data length]];
    }
}

@end
