//
//  BWVoteCell.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/11.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BWVoteCell : UITableViewCell

@property (nonatomic) UILabel *counter;
@property (nonatomic) UILabel *voter;
@property (nonatomic) UILabel *voteder;

-(void)setVoterString:(NSString*)voterString votedString:(NSString*)votedString count:(NSInteger)count cellSize:(CGSize)cellSize;
@end
