//
//  BWGorgeousTableView.m
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/10.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import "BWGorgeousTableView.h"
#import <SpriteKit/SpriteKit.h>

@implementation BWGorgeousTableView

-(void)setViewDesign :(id)delegate {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    UIImage *image = [UIImage imageNamed:@"ui_frameTable.png"];
    UIImage *resizedImage = [image resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30)];
    UIImageView *resizableView = [[UIImageView alloc] initWithImage:resizedImage];
    [resizableView setContentMode:UIViewContentModeScaleToFill];
    [resizableView setFrame:CGRectMake(0, 0, width,height)];
    
    [self addSubview:resizableView];
    
    CGFloat margin = 20.0;
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(margin,margin,width-margin*2,height-margin*2)];
    self.tableView.delegate = delegate;
    self.tableView.dataSource = delegate;
    
    UIColor* tableBackgroundColor = [UIColor blackColor];
    tableBackgroundColor = [tableBackgroundColor colorWithAlphaComponent:0.0];
    self.tableView.backgroundColor = tableBackgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self addSubview:self.tableView];
}

+(UITableViewCell*)makePlateCellWithReuseIdentifier:(NSString*)name colorId:(NSInteger)colorId {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:name];
    NSString *filename = @"";
    if(colorId == 0) filename = @"ui_plate.png";
    if(colorId == 1) filename = @"ui_plate_red.png";
    UIImage *image = [UIImage imageNamed:filename];
    
    UIImage *resizedImage = [image resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)];
    UIImageView *resizableView = [[UIImageView alloc] initWithImage:resizedImage];
    [resizableView setContentMode:UIViewContentModeScaleToFill];
    [resizableView setFrame:CGRectMake(0, 0, cell.frame.size.width,cell.frame.size.height)];
    
    cell.backgroundView = resizableView;
    cell.backgroundColor = nil;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

@end
