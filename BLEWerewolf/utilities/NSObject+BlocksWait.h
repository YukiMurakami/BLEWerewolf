//
//  NSObject+BlocksWait.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/12/20.
//  Copyright © 2015年 yuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BlocksWait)

+ (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay;

@end
