//
//  LWRoleSettingScene.m
//  嘘つき人狼
//
//  Created by Yuki Murakami on 2014/09/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#import "LWRoleSettingScene.h"
#import "BWUtility.h"
#import "LWPickerTableScene.h"

@implementation LWRoleSettingScene

-(id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    return self;
}

-(void)initBackground {
    
    SKSpriteNode *background = [[SKSpriteNode alloc]initWithImageNamed:@"night.jpg"];
    background.size = self.size;
    background.position = CGPointMake(self.size.width/2,self.size.height/2);
    [self addChild:background];
    
    CGSize buttonSize = CGSizeMake(self.size.width*0.8, self.size.width*0.8/5);
    CGFloat margin = buttonSize.height*0.25;
    NSArray *buttonInfos = @[@{@"text":@"戻る",@"name":@"back",@"y":@(-self.size.height/2+margin+buttonSize.height/2)},
                             @{@"text":@"推奨設定",@"name":@"default",@"y":@(-self.size.height/2+margin*2+buttonSize.height/2*3)},
                             ];
    for(NSDictionary *info in buttonInfos) {
        SKSpriteNode *button = [BWUtility makeButton:info[@"text"] size:buttonSize name:info[@"name"] position:CGPointMake(0, [info[@"y"]floatValue])];
        [background addChild:button];
    }
    
    
    SKLabelNode *playCount = [[SKLabelNode alloc]init];
    int playc = [infoDic[@"playerCount"]intValue];
    playCount.text = [NSString stringWithFormat:@"プレイヤー数：%d人",playc ];
    playCount.fontName = @"HiraKakuProN-W6";
    playCount.fontSize = buttonSize.height/2;
    playCount.position = CGPointMake(0,self.size.height/2-22-playCount.fontSize/2-margin);
    [background addChild:playCount];
    
    table = [[UITableView alloc]initWithFrame:CGRectMake((self.size.width-buttonSize.width)/2,22+margin*2+playCount.fontSize*0.8,buttonSize.width,self.size.height - (margin*5 + buttonSize.height*2.4 + 22))];
    table.delegate = self;
    table.dataSource = self;
    table.rowHeight = table.frame.size.height/4;
}


-(void) setBackScene :(SKScene *)backScene infoDic:(NSMutableDictionary *)_infoDic{
    toBackScene = (BWSettingScene *)backScene;
    infoDic = _infoDic;
    rollArray = infoDic[@"rollArray"];
    nPlayer = [infoDic[@"playerCount"]intValue];
    [self initBackground];
}

-(void)willMoveFromView:(SKView *)view {
    [table removeFromSuperview];
}

-(void)didMoveToView:(SKView *)view {
    
    [self.view addSubview:table];
    [table reloadData];
}

-(void)cellEdit :(NSNumber *)_row{
    
    selectedIndex = [_row intValue];
    
    if(selectedIndex != 0) {
        [self showPicker :selectedIndex];
    }
}

-(void)villagerCount {
    int sum = 0;
    for(int i=1;i<rollArray.count;i++) {
        sum += [rollArray[i]intValue];
    }
    
    int village = nPlayer - sum;
    rollArray[RoleVillager] = @(village);
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    
    if([node.name isEqualToString:@"back"]) {
        [(BWSettingScene *) toBackScene setRollInfo:rollArray] ;
        SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.5];
        [self.view presentScene:toBackScene transition:transition];
    }
    
    if([node.name isEqualToString:@"default"]) {
        //デフォルト設定を入力
        NSMutableArray *array = [BWUtility getDefaultRoleArray:[infoDic[@"playerCount"]intValue]];
        for(NSInteger i=0;i<array.count;i++) {
            rollArray[i] = array[i];
        }
        [table reloadData];
    }
}


- (void)showPicker :(NSInteger)row {
    LWPickerTableScene *pickerTableScene = [LWPickerTableScene sceneWithSize:self.size];

    pickerTableScene.maxNumber = MIN([infoDic[@"playerCount"]integerValue],[[BWUtility getCardInfofromId:(int)row][@"maxPlayer"]integerValue]);
    pickerTableScene.rollString = [BWUtility getCardInfofromId:(int)row][@"name"];
    pickerTableScene.currentNumber = [rollArray[row]intValue];
    pickerTableScene.backRow = row;
    pickerTableScene.toBackScene = self;
    [pickerTableScene initBackgroundScene];
    
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.5];
    [self.view presentScene:pickerTableScene transition:transition];
}

- (void)setCount :(NSInteger)row count:(NSInteger)count {
    rollArray[row] = @(count);
    [self villagerCount];
}

/*

#pragma mark -
#pragma mark pickerViewDelegate

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return nPlayer+1;
}
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *pic = [NSString stringWithFormat:@"%d人",row];
    return pic;
}


- (void)showPicker {
    pickerViewPopup = [[UIActionSheet alloc] initWithTitle:@"select hoge"
                                                  delegate:self
                                         cancelButtonTitle:nil
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:nil];

    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0,44,0,0)];
    picker.delegate = self;
    picker.showsSelectionIndicator = YES;
    picker.backgroundColor = [UIColor whiteColor];
    
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    pickerToolbar.barStyle = UIBarStyleBlackOpaque;
    [pickerToolbar sizeToFit];
    
    NSMutableArray *barItems = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [barItems addObject:flexSpace];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(closePicker:)];
    [barItems addObject:doneBtn];
    
    [pickerToolbar setItems:barItems animated:YES];
    
    [pickerViewPopup addSubview:pickerToolbar];
    [pickerViewPopup addSubview:picker];
    [pickerViewPopup showInView:self.view];
    
    [pickerViewPopup setBounds:CGRectMake(0,0,320, 400)];
}

-(BOOL)closePicker:(id)sender {
    
    int num = [picker selectedRowInComponent:0];
    
    [pickerViewPopup dismissWithClickedButtonIndex:0 animated:YES];
    
    NSMutableArray *rollArray2 = [rollArray mutableCopy];
    
    [rollArray2 replaceObjectAtIndex:selectedIndex withObject:@(num)];
    
    rollArray = rollArray2;
    
    [self villagerCount];
    
    [table reloadData];
    
    return YES;
}
*/

#pragma mark -
#pragma mark tableDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return rollArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    }
    
    NSString *name = [BWUtility getCardInfofromId:(int)indexPath.row][@"name"];
    int count = [rollArray[indexPath.row]intValue];
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"card%d.png",(int)indexPath.row]];
    
    cell.textLabel.text = name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count ];
    cell.imageView.image = image;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self performSelector:@selector(cellEdit:) withObject:@(indexPath.row)];
}


@end
