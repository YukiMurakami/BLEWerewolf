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

@implementation BWUserSettingScene

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
    
    SKLabelNode *identificationStringNode = [[SKLabelNode alloc]init];
    identificationStringNode.text = [NSString stringWithFormat:@"ID:%@",[BWUtility getIdentificationString]];
    identificationStringNode.fontSize = 30.0;
    identificationStringNode.fontColor = [UIColor blackColor];
    identificationStringNode.position = CGPointMake(0, self.size.height/2 - 30.0 - self.size.height*0.05);
    [backgroundNode addChild:identificationStringNode];
    
    NSString *userName = @"no_name";
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userData = [ud objectForKey:@"userData"];
    if(userData) {
        userName = userData[@"name"];
    }
    SKLabelNode *nameStringNode = [[SKLabelNode alloc]init];
    nameStringNode.text = userName;
    nameStringNode.fontColor = [UIColor blackColor];
    nameStringNode.fontSize = 50.0;
    nameStringNode.position = CGPointMake(0, self.size.height/2 - (30.0 + self.size.height*0.05)*2);
    [backgroundNode addChild:nameStringNode];
    
    SKSpriteNode *buttonNode2 = [BWUtility makeButton:@"名前変更" size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"rename" position:CGPointMake(0, -self.size.height/2 + self.size.width*0.7*0.2*4)];
    [backgroundNode addChild:buttonNode2];
    
    SKSpriteNode *buttonNode = [BWUtility makeButton:@"戻る" size:CGSizeMake(self.size.width*0.7,self.size.width*0.7*0.2) name:@"back" position:CGPointMake(0, -self.size.height/2 + self.size.width*0.7*0.2*2)];
    [backgroundNode addChild:buttonNode];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"back"]) {
        BWTopScene *scene = [BWTopScene sceneWithSize:self.size];
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:1.0];
        [self.view presentScene:scene transition:transition];
    }
    
    if([node.name isEqualToString:@"rename"]) {
        [self prompt];
    }
    
}

-(void)prompt
{
    
    __weak typeof(self) weakSelf = self;
    
    @autoreleasepool {
        NSString *title = @"ユーザ名前変更";
        NSString *message = @"新しい名前を入力してください。";
        NSString *buttonTitle = @"変更";
        
        UIAlertController * alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        void (^configurationHandler)(UITextField *) = ^(UITextField * textField) {
            textField.placeholder = @"Player name";
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
                    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                    NSMutableDictionary *userData = [[ud objectForKey:@"userData"]mutableCopy];
                    if(!userData) {
                        userData = [NSMutableDictionary dictionary];
                    }
                    [userData setObject:textField.text forKey:@"name"];
                    [ud setObject:userData forKey:@"userData"];
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
