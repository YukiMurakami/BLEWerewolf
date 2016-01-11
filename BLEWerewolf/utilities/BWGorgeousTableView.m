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
    
    NSString *filename_push = @"";
    if(colorId == 0) filename_push = @"ui_platePush.png";
    if(colorId == 1) filename_push = @"ui_plate_red.png";
    UIImage *image_push = [UIImage imageNamed:filename_push];
    
    UIImage *resizedImage_push = [image_push resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)];
    UIImageView *resizableView_push = [[UIImageView alloc] initWithImage:resizedImage_push];
    [resizableView_push setContentMode:UIViewContentModeScaleToFill];
    [resizableView_push setFrame:CGRectMake(0, 0, cell.frame.size.width,cell.frame.size.height)];
    
    
    
    cell.backgroundView = resizableView;
    cell.backgroundColor = nil;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    NSLog(@"%f",cell.frame.size.height);
    cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.frame.size.height*0.5];
    //cell.textLabel.minimumScaleFactor = 10.f/15.f;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    //[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.selectedBackgroundView = resizableView_push;
    
    return cell;
}

@end
