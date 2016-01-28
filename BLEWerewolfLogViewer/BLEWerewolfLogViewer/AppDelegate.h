//
//  AppDelegate.h
//  BLEWerewolfLogViewer
//
//  Created by Yuki Murakami on 2016/01/28.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, Role) {
    RoleVillager,
    RoleWerewolf,
    RoleFortuneTeller,
    RoleShaman,
    RoleMadman,
    RoleBodyguard,
    RoleJointOwner,
    RoleFox,
    RoleCat,
    //TODO::役職追加時変更点
};

@interface AppDelegate : NSObject <NSApplicationDelegate,NSNetServiceDelegate>


- (void)acceptConnect:(NSNotification *)aNotification;

@end

