//
//  AppDelegate.m
//  BLEWerewolfLogViewer
//
//  Created by Yuki Murakami on 2016/01/28.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "AppDelegate.h"

#define PORT_NUMBER_START 8888
#define PORT_NUMBER_END 8899

@interface AppDelegate () {
    NSInteger nowPortNumber;
}
@property (unsafe_unretained) IBOutlet NSTextView *werewolfTextView;
@property (unsafe_unretained) IBOutlet NSTextView *madmanTextView;
@property (unsafe_unretained) IBOutlet NSTextView *fortuneTellerTextView;
@property (unsafe_unretained) IBOutlet NSTextView *shamanTextView;
@property (unsafe_unretained) IBOutlet NSTextView *bodyguardTextView;
@property (unsafe_unretained) IBOutlet NSTextView *foxTextView;
@property (unsafe_unretained) IBOutlet NSTextView *catTextView;
@property (unsafe_unretained) IBOutlet NSTextView *villagerTextView;
@property (unsafe_unretained) IBOutlet NSTextView *gmTextView;
@property (unsafe_unretained) IBOutlet NSTextView *masonTextView;


@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    nowPortNumber = PORT_NUMBER_START;
    
    [self publishNetService];
    
    CGFloat fontSize = 21;
    [self.gmTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.werewolfTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.villagerTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.fortuneTellerTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.shamanTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.madmanTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.catTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.foxTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.masonTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
    [self.bodyguardTextView setFont:[NSFont fontWithName:@"HiraKakuProN-W3" size:fontSize]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




#pragma mark - Bonjour Implementation



NSSocketPort* socket_;
NSNetService *service_;
NSFileHandle *socketHandle_;
NSFileHandle* readHandle_;

- (void)publishNetService
{
    socket_ = [[NSSocketPort alloc] initWithTCPPort:nowPortNumber];
    if (socket_)
    {
        service_ = [[NSNetService alloc] initWithDomain:@"" type:@"_test._tcp" name:[NSString stringWithFormat:@"Hello Bonjour %ld",nowPortNumber] port:(int)nowPortNumber];
        if (service_)
        {
            service_.delegate = self;
            // [service_ scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [service_ publish];
        }
        else
        {
            NSLog(@"invalid NSNetSevice");
        }
    }
    else
    {
        NSLog(@"invalid NSSocketPort:%ld",nowPortNumber);
        nowPortNumber++;
        if(nowPortNumber > PORT_NUMBER_END) {
            nowPortNumber = PORT_NUMBER_START;
        }
        [self publishNetService];
    }
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"%@", [sender description]);
    socketHandle_ = [[NSFileHandle alloc] initWithFileDescriptor:[socket_ socket] closeOnDealloc:YES];
    if (socketHandle_)
    {
        NSLog(@"has sockethandle");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptConnect:) name:NSFileHandleConnectionAcceptedNotification object:socketHandle_];
        [socketHandle_ acceptConnectionInBackgroundAndNotify];
    }
}

- (void)acceptConnect:(NSNotification *)aNotification
{
    NSLog(@"%@", [aNotification description]);
    readHandle_ = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveData:) name:NSFileHandleDataAvailableNotification object:readHandle_];
    [readHandle_ waitForDataInBackgroundAndNotify];
}

- (void)recieveData:(NSNotification *)aNotification
{
    [self.window orderFront:self];
    
    NSData *data = [readHandle_ availableData];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
    //コマンドの形式は「R/-/N..N/-/M..M」役職ID,名前,メッセージ
    
    NSArray *array = [string componentsSeparatedByString:@"/-/"];
    
    NSInteger roleId = [array[0]integerValue];
    NSString *name = array[1];
    NSString *message = array[2];
    
    NSTextView *targetView = self.gmTextView;
    switch (roleId) {
        case RoleVillager: targetView = self.villagerTextView; break;
        case RoleWerewolf: targetView = self.werewolfTextView; break;
        case RoleFortuneTeller: targetView = self.fortuneTellerTextView; break;
        case RoleShaman: targetView = self.shamanTextView; break;
        case RoleBodyguard: targetView = self.bodyguardTextView; break;
        case RoleFox: targetView = self.foxTextView; break;
        case RoleCat: targetView = self.catTextView; break;
        case RoleJointOwner: targetView = self.masonTextView; break;
        case RoleMadman: targetView = self.madmanTextView; break;
        default:
            break;
    }
    
    //[targetView insertText:[NSString stringWithFormat:@"%@\r\n%@:「%@」",targetView.string,name,message]];
    [targetView insertText:[NSString stringWithFormat:@"\r\n%@:「%@」",name,message]];
    
    [readHandle_ waitForDataInBackgroundAndNotify];
}



@end
