//
//  NSObject+BlocksWait.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/12/20.
//  Copyright © 2015年 yuki. All rights reserved.
//

#import "NSObject+BlocksWait.h"

@implementation NSObject (BlocksWait)

+ (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end
