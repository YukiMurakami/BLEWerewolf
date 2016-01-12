//
//  BWVoteCell.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/11.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWVoteCell.h"

@implementation BWVoteCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)setVoterString:(NSString*)voterString votedString:(NSString*)votedString count:(NSInteger)count cellSize:(CGSize)cellSize {
    CGFloat cellWidth = cellSize.width;
    CGFloat cellHeight = cellSize.height;
    
    self.counter = [[UILabel alloc]initWithFrame:CGRectMake(cellWidth*1/41, cellHeight*0.3, cellWidth*4/41, cellHeight*0.5)];
    self.counter.text = [NSString stringWithFormat:@"%d票",(int)count];
    self.counter.textColor = [UIColor whiteColor];
    self.counter.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.counter];
    
    self.voter = [[UILabel alloc]initWithFrame:CGRectMake(cellWidth*6/41, cellHeight*0.3, cellWidth*12/41, cellHeight*0.5)];
    self.voter.text = voterString;
    self.voter.textColor = [UIColor whiteColor];
    self.voter.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.voter];
    
    self.voteder = [[UILabel alloc]initWithFrame:CGRectMake(cellWidth*24/41, cellHeight*0.3, cellWidth*12/41, cellHeight * 0.5)];
    self.voteder.text = votedString;
    self.voteder.textColor = [UIColor whiteColor];
    self.voteder.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.voteder];
    
    
    self.backgroundView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"ui_tableItem_vector.png"]];
}

@end
