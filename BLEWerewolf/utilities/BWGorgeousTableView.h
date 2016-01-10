//
//  BWGorgeousTableView.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2016/01/10.
//  Copyright © 2016年 yuki. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BWGorgeousTableView : UIView  {
    
}

@property (nonatomic) UITableView *tableView;

-(void)setViewDesign :(id)delegate;


+(UITableViewCell*)makePlateCellWithReuseIdentifier:(NSString*)name colorId:(NSInteger)colorId;
@end
