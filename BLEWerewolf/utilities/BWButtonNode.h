//
//  BWButtonNode.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/10.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@protocol BWButtonNodeDelegate
- (void)buttonNode:(SKSpriteNode*)buttonNode didPushedWithName:(NSString*)name;
@end

@interface BWButtonNode : SKSpriteNode {
    id<BWButtonNodeDelegate> _delegate;
}
@property (nonatomic) id<BWButtonNodeDelegate> delegate;

-(void)makeButtonWithSize:(CGSize)size name:(NSString*)name title:(NSString*)title boldRate:(CGFloat)_boldRate;

@end
