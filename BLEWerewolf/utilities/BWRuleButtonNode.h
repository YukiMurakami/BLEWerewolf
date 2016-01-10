//
//  BWRuleButtonNode.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/10.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@protocol BWRuleButtonNodeDelegate
- (void)buttonNode:(SKSpriteNode*)buttonNode didPushedWithName:(NSString*)name;
@end

@interface BWRuleButtonNode : SKSpriteNode {
    id<BWRuleButtonNodeDelegate> _delegate;
}
@property (nonatomic) id<BWRuleButtonNodeDelegate> delegate;

@property (nonatomic) SKLabelNode *title;
@property (nonatomic) SKLabelNode *param;

-(void)makeButtonWithSize:(CGSize)size name:(NSString*)name title:(NSString*)title param:(NSString*)param delegate:(id)delegateid;

@end
