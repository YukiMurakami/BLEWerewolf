//
//  BWUserSettingScene.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/01.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWTopScene.h"
#import "BWUserSettingScene.h"
#import "BWUtility.h"
#import "BWSocketManager.h"


@implementation BWUserSettingScene {
    BOOL isRename;
}

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    [self initBackground];
    
    return self;
}

-(void)initBackground {
    backgroundNode = [[SKSpriteNode alloc]init];
    backgroundNode.size = self.size;
    backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    backgroundNode.texture = [SKTexture textureWithImageNamed:@"afternoon.jpg"];
    [self addChild:backgroundNode];
    
    NSArray *infos = @[@{@"string":[NSString stringWithFormat:@"ID:%@",[BWUtility getIdentificationString]],@"fontSize":@(50)},
                       @{@"string":[BWUtility getUserName],@"fontSize":@(50)},
                       @{@"string":[BWUtility getUserHostIP],@"fontSize":@(50),},
                       ];
    for(NSInteger i=0;i<infos.count;i++) {
        SKSpriteNode *titleNode = [BWUtility makeTitleNodeWithBoldrate:1.0 size:CGSizeMake(self.size.width*0.8, self.size.width*0.8/200*[infos[i][@"fontSize"]doubleValue]) title:infos[i][@"string"]];
        double y = self.size.height/2 - [infos[i][@"fontSize"]doubleValue]/2 - self.size.height*0.05*2;
        for(NSInteger j=0;j<i;j++) {
            y -= [infos[j][@"fontSize"]doubleValue]/2 + [infos[j+1][@"fontSize"]doubleValue]/2;
            y -= self.size.height*0.05;
        }
        titleNode.position = CGPointMake(0, y);
        [backgroundNode addChild:titleNode];
    }
    
    
    NSArray *buttonInfos = @[@{@"title":@"名前変更",@"name":@"rename",@"y":@(-self.size.height/2 + self.size.width*0.7*0.2*6)},
                             @{@"title":@"IP変更",@"name":@"host",@"y":@(-self.size.height/2 + self.size.width*0.7*0.2*4)},
                             @{@"title":@"戻る",@"name":@"back",@"y":@(-self.size.height/2 + self.size.width*0.7*0.2*2)}
                             ];
    
    CGSize buttonSize = CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2);
    for(NSInteger i=0;i<buttonInfos.count;i++) {
        BWButtonNode *node = [[BWButtonNode alloc]init];
        node.delegate = self;
        [node makeButtonWithSize:buttonSize name:buttonInfos[i][@"name"] title:buttonInfos[i][@"title"] boldRate:0.7];
        node.position = CGPointMake(0, [buttonInfos[i][@"y"]doubleValue]);
        [backgroundNode addChild:node];
    }
}

- (void)buttonNode:(SKSpriteNode *)buttonNode didPushedWithName:(NSString *)name {
    if([name isEqualToString:@"back"]) {
        BWTopScene *scene = [BWTopScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
    
    if([name isEqualToString:@"rename"] || [name isEqualToString:@"host"]) {
        if([name isEqualToString:@"rename"]) {
            isRename = YES;
        } else {
            isRename = NO;
        }
        [self prompt];
    }
}



-(void)prompt
{
    
    __weak typeof(self) weakSelf = self;
    
    @autoreleasepool {
        NSString *title = @"ユーザ名前変更";
        NSString *message = @"新しい名前を入力してください。";
        if(!isRename) {
            title = @"接続先ホスト変更";
            message = @"新しい接続先IPアドレス(n.n.n.n)を入力してください。";
        }
        NSString *buttonTitle = @"変更";
        
        UIAlertController * alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        void (^configurationHandler)(UITextField *) = ^(UITextField * textField) {
            textField.placeholder = @"Player name";
            if(isRename) {
                textField.text = [BWUtility getUserName];
            } else {
                textField.text = [BWUtility getUserHostIP];
            }
            // ここで UITextField の text が変更したときの通知を受信する設定を実施
            NSLog(@"ここで UITextField の text が変更したときの通知を受信する設定を実施");
            [[NSNotificationCenter defaultCenter]
             addObserver:weakSelf
             selector:@selector(alertTextFieldDidChange:)
             name:UITextFieldTextDidChangeNotification
             object:textField];
        };
        [alertController addTextFieldWithConfigurationHandler:configurationHandler];
        
        void (^cancelHandler)(UIAlertAction *) = ^(UIAlertAction * action) {
            // UITextField 変更通知は不要
            [[NSNotificationCenter defaultCenter]
             removeObserver:weakSelf
             name:UITextFieldTextDidChangeNotification
             object:nil];
        };
        UIAlertAction * cancelAction =
        [UIAlertAction actionWithTitle:@"戻る"
                                 style:UIAlertActionStyleCancel
                               handler:cancelHandler];
        [alertController addAction:cancelAction];
        
        void (^createHandler)(UIAlertAction *) = ^(UIAlertAction * action) {
            UITextField * textField = alertController.textFields[0];
            if (textField.text.length > 0) {
                dispatch_block_t mainBlock = ^{
                    // ここに UI の更新やデータベースへの追記などを実施するコードを記述する
                    NSLog(@"ここに UI の更新やデータベースへの追記などを実施するコードを記述する");
                    //名前変更
                    if(isRename) {
                        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                        NSMutableDictionary *userData = [[ud objectForKey:@"userData"]mutableCopy];
                        if(!userData) {
                            userData = [NSMutableDictionary dictionary];
                        }
                        [userData setObject:textField.text forKey:@"name"];
                        [ud setObject:userData forKey:@"userData"];
                    } else {
                        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                        NSMutableDictionary *userData = [[ud objectForKey:@"userData"]mutableCopy];
                        if(!userData) {
                            userData = [NSMutableDictionary dictionary];
                        }
                        [userData setObject:textField.text forKey:@"hostAddress"];
                        [ud setObject:userData forKey:@"userData"];
                        [[BWSocketManager sharedInstance] changeIPAddress];
                    }
                    [self initBackground];
                };
                dispatch_async(dispatch_get_main_queue(), mainBlock);
            }
            // 通知はもう要らない
            [[NSNotificationCenter defaultCenter]
             removeObserver:weakSelf
             name:UITextFieldTextDidChangeNotification
             object:nil];
        };
        UIAlertAction * createAction =
        [UIAlertAction actionWithTitle:buttonTitle
                                 style:UIAlertActionStyleDefault
                               handler:createHandler];
        createAction.enabled = NO; // 最初は「作成」ボタンは押せない
        [alertController addAction:createAction];
        
        [self.view.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - NSNotification handler
// ここで UITextField の入力処理を行う
-(void)alertTextFieldDidChange:(NSNotification *)notification
{
    UIAlertController * alertController = (UIAlertController *)self.view.window.rootViewController.presentedViewController;
    if (alertController) {
        UITextField *   textField    = alertController.textFields.firstObject;
        UIAlertAction * createAction = alertController.actions.lastObject;
        // 文字入力があればボタンを押せるようにする。
        if(textField.text.length > 0) {
            createAction.enabled = YES;
        } else {
            createAction.enabled = NO;
        }
    }
}

@end
