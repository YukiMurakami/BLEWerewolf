//
//  AppDelegate.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/23.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BWViewController.h"

@interface BWAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (BWViewController*)getRootViewController;

@end

