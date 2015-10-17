//
//  DHSlideMenuViewController.m
//  ByqIOSApps
//
//  Created by DumbbellYang on 14/11/28.
//  Copyright (c) 2014年 DumbbellYang. All rights reserved.
//

#import "DHSlideMenuViewController.h"
#import "DHSlideMenuController.h"
#import "TimeIntervalUtils.h"
#import "HBUserEntity.h"
#import "HBDataSaveManager.h"

#define KTableHeaderHeight  150
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
static NSString * const kSlideMenuViewControllerCellReuseId = @"kSlideMenuViewControllerCellReuseId";

@interface DHSlideMenuViewController ()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSArray *titles;
@property(nonatomic, strong) NSArray *images;
@property(nonatomic, strong) NSArray *controllers;
@property(nonatomic, strong) UIColor *titleColor;
@property(nonatomic, strong) UIColor *backgroundColor;
@property(nonatomic, strong) UIColor *selectedColor;

@property(nonatomic, strong) UIImageView *msgRedPointView;
@property(nonatomic, strong) UIImageView *examRedPointView;

@end

@implementation DHSlideMenuViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //获取新消息列表成功通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getMsgSuccess) name:kNotification_GetMsgSuccess object:nil];
        
        //学生获取作业列表成功通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getExamSuccess) name:kNotification_GetExamSuccess object:nil];
    }
    return self;
}

- (void)setMenus:(NSArray *)titles MenuImages:(NSArray *)images TabBarControllers:(NSArray*)controllers;{
    NSParameterAssert(titles);
    _titles = titles;
    _images = images;
    _controllers = controllers;
}

#pragma mark - Managing the view

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, ScreenWidth, ScreenHeight)];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = NO;
        _tableView.backgroundColor = [UIColor whiteColor];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kSlideMenuViewControllerCellReuseId];
        [self.view addSubview:_tableView];
    }
}

#pragma mark - Configuring the view’s layout behavior
- (UIStatusBarStyle)preferredStatusBarStyle
{
    // Even if this view controller hides the status bar, implementing this method is still needed to match the center view controller's
    // status bar style to avoid a flicker when the drawer is dragged and then left to open.
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)headButtonAction:(id)sender
{
    DHSlideMenuController *svc = [DHSlideMenuController sharedInstance];
    [svc hideSlideMenuViewController:YES];
    
    Class viewCtlClass = NSClassFromString(_headerClassName);
    if (viewCtlClass && [viewCtlClass isSubclassOfClass:[UIViewController class]]) {
        UIViewController *viewController = [[viewCtlClass alloc] init];
        [[AppDelegate delegate].globalNavi pushViewController:viewController animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSParameterAssert(self.titles);
    return self.titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return KTableHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithHex:0xe4e4e4];
    
    float controlX = 20;
    float controlH = 50;
    float controlY = KTableHeaderHeight - controlH - 20;
    UIImageView *headView = [[UIImageView alloc] initWithFrame:CGRectMake(controlX, controlY, controlH, controlH)];
    headView.image = [UIImage imageNamed:@"menu_user_pohoto"];
    [view addSubview:headView];
    
    controlX += controlH + 10;
    float controlW = self.viewWidth - controlX;
    UIButton *buttonInfo = [[UIButton alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    buttonInfo.backgroundColor = [UIColor clearColor];
    [buttonInfo addTarget:self action:@selector(headButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:buttonInfo];
    
    UIColor *textColor = RGBCOLOR(93, 85, 95);
    UIFont *font = [UIFont systemFontOfSize:20];
    float typeW = 70;
    controlX = 0;
    controlY = 0;
    controlH = 25;
    controlW = buttonInfo.frame.size.width-controlH-typeW-10;
    if ([_headerName length] > 0) {
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
        nameLbl.backgroundColor = [UIColor clearColor];
        nameLbl.textColor = textColor;
        nameLbl.font = font;
        nameLbl.text = _headerName;
        [buttonInfo addSubview:nameLbl];
    }
    
    controlY += controlH;
    controlW = 150;
    UILabel *phoneLbl = [[UILabel alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    phoneLbl.backgroundColor = [UIColor clearColor];
    phoneLbl.textColor = textColor;
    phoneLbl.font = font;
    phoneLbl.text = _headerPhone;
    [buttonInfo addSubview:phoneLbl];
    
    float arrowX = buttonInfo.frame.size.width - controlH - 10;
    controlY = 15;
    UIImageView *arrowImg = [[UIImageView alloc] initWithFrame:CGRectMake(arrowX, controlY, controlH, controlH)];
    arrowImg.image = [UIImage imageNamed:@"menu_icon_user_open"];
    [buttonInfo addSubview:arrowImg];
    
    if ([_headerName length] == 0) {
        controlX = 0;
    } else {
        controlX = arrowX-typeW-5;
    }
    controlY = 0;
    UIView *typeView = [self createTypeView:CGRectMake(controlX, controlY, typeW, controlH)];
    [buttonInfo addSubview:typeView];
    
    return view;
}

- (UIView *)createTypeView:(CGRect)frame
{
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:frame];
    UILabel *typeLbl = [[UILabel alloc] initWithFrame:bgView.bounds];
    typeLbl.textAlignment = NSTextAlignmentCenter;
    typeLbl.textColor = [UIColor whiteColor];
    typeLbl.font = [UIFont systemFontOfSize:16];
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity.type == 1) {
        if (_headerVipTime == 0) {
            typeLbl.text = @"普通用户";
            bgView.image = [UIImage imageNamed:@"studentmanage-bg-normal-user"];
        } else {
            NSTimeInterval cur = [NSDate date].timeIntervalSince1970;
            if (_headerVipTime < cur) {
                //vip过期
                typeLbl.text = @"VIP过期";
                bgView.image = [UIImage imageNamed:@"studentmanage-bg-vipover-user"];
            } else {
                typeLbl.text = @"VIP会员";
                bgView.image = [UIImage imageNamed:@"studentmanage-bg-vip-user"];
            }
        }
    } else if (userEntity.type == 10) {
        typeLbl.text = @"教师";
        bgView.image = [UIImage imageNamed:@"studentmanage-bg-normal-user"];
    } else {
        typeLbl.text = @"教研员";
        bgView.image = [UIImage imageNamed:@"studentmanage-bg-normal-user"];
    }
    [bgView addSubview:typeLbl];
    return bgView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(self.titles);
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSlideMenuViewControllerCellReuseId forIndexPath:indexPath];
    if ((self.images != nil) && (self.images.count > indexPath.row)){
        cell.imageView.image = [UIImage imageNamed:[self.images objectAtIndex:indexPath.row]];
    }
    
    NSString *viewCtlName = self.controllers[indexPath.row];
    
    cell.backgroundColor = self.backgroundColor;
    cell.textLabel.text = [self.titles objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
//    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if ([viewCtlName isEqualToString:@"HBMessageViewController"]) { //消息中心
        if (!self.msgRedPointView) {
            self.msgRedPointView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"msg_tips_new"]];
            self.msgRedPointView.frame = CGRectMake(150, (60 - 15)/2, 15, 15);
            [cell addSubview:self.msgRedPointView];
        }
        
        if([AppDelegate delegate].hasNewMsg){
            self.msgRedPointView.hidden = NO;
        }else{
            self.msgRedPointView.hidden = YES;
        }
    }
    
    if ([viewCtlName isEqualToString:@"HBTestWorkViewController"]) { //我的作业
        if (!self.examRedPointView) {
            self.examRedPointView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"msg_tips_new"]];
            self.examRedPointView.frame = CGRectMake(150, (60 - 15)/2, 15, 15);
            [cell addSubview:self.examRedPointView];
        }
        
        if([AppDelegate delegate].hasNewExam){
            self.examRedPointView.hidden = NO;
        }else{
            self.examRedPointView.hidden = YES;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DHSlideMenuController *svc = [DHSlideMenuController sharedInstance];
    NSInteger index = indexPath.row;
    NSLog(@"select row:%ld", (long)index);
    if (index < [self.controllers count]){
        [svc resetCurrentViewToMainViewController];
        
        NSString *viewCtlName = self.controllers[index];
        
        if ([viewCtlName isEqualToString:@""]) { //联系客服
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您确定要拨打客服电话？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            alertView.tag = 0;
            
            [alertView show];
        }
        
        Class viewCtlClass = NSClassFromString(viewCtlName);
        if (viewCtlClass && [viewCtlClass isSubclassOfClass:[UIViewController class]]) {
            UIViewController *viewController = [[viewCtlClass alloc] init];
            [[AppDelegate delegate].globalNavi pushViewController:viewController animated:YES];
        }
    }
    
    [svc hideSlideMenuViewController:YES];
}

#pragma mark - actionSheetDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        
    }else{
        NSString *allString = [NSString stringWithFormat:@"tel:4008126161"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:allString]];
    }
}

-(void)getMsgSuccess
{
    [_tableView reloadData];
}

-(void)getExamSuccess
{
    [_tableView reloadData];
}

#if 0
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
}
#endif

@end
