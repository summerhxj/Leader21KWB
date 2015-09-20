//
//  HBSettingViewController.m
//  LeaderDiandu
//
//  Created by xijun on 15/9/1.
//  Copyright (c) 2015年 hxj. All rights reserved.
//

#import "HBSettingViewController.h"
#import "HBTitleView.h"
#import "UIViewController+AddBackBtn.h"
#import "HBBookManViewController.h"

#import "HBServiceManager.h"

static NSString * const KSettingViewControllerCellSwitchReuseId = @"KSettingViewControllerCellSwitchReuseId";
static NSString * const KSettingViewControllerCellAccessoryReuseId = @"KSettingViewControllerCellAccessoryReuseId";

@interface HBSettingViewController ()<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
    NSArray     *_titleArr;
    UITableView *_tableView;
}

@property (nonatomic, strong) UIButton* logoutButton;

@end

@implementation HBSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _titleArr = @[@"仅用WiFi下载图书", @"显示英文书名", @"本地图书管理", @"检查更新", @"欢迎页", @"关于课外宝"];
    
    HBTitleView *labTitle = [HBTitleView titleViewWithTitle:@"设置" onView:self.view];
    [self.view addSubview:labTitle];
    
    [self addBackButton];
    
    CGRect rect = self.view.frame;
    CGRect viewFrame = CGRectMake(0, KHBNaviBarHeight, rect.size.width, rect.size.height-KHBNaviBarHeight);
    _tableView = [[UITableView alloc] initWithFrame:viewFrame];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    CGRect rc = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 70.0f);
    UIView* view = [[UIView alloc] initWithFrame:rc];
    rc.origin.x += 20.0f;
    rc.size.width -= 40.0f;
    rc.origin.y += 20.0f;
    rc.size.height -= 30.0f;
    
    self.logoutButton = [[UIButton alloc] initWithFrame:rc];
    [self.logoutButton setBackgroundImage:[UIImage imageNamed:@"user_button"] forState:UIControlStateNormal];
    [self.logoutButton setTitle:@"退出帐号" forState:UIControlStateNormal];
    [self.logoutButton addTarget:self action:@selector(logoutButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:self.logoutButton];
    _tableView.tableFooterView = view;
}

- (void)logoutButtonPressed:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"您确定要退出帐号？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.tag = 0;
    
    [alertView show];
}

#pragma mark - actionSheetDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        //to do ...
    }else{
        //to do 注销...
        HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
        [[HBServiceManager defaultManager] requestLogout:userEntity.name token:userEntity.token completion:^(id responseObject, NSError *error) {
            if (responseObject) {
                NSDictionary *dic = responseObject;
                if ([dic[@"result"] isEqualToString:@"OK"]) {
                    //注销成功
                    [[HBDataSaveManager defaultManager] clearUserData];
                    [Navigator pushLoginController];
                }
            }
        }];
    }
}

- (void)wifiDownload:(id)sender
{
    BOOL aWifiDownload = YES;
    UISwitch *aSwitch = (UISwitch *)sender;
    if (aSwitch.isOn) {
        aWifiDownload = YES;
    }else{
        aWifiDownload = NO;
    }
    
    BOOL aShowEnBookName = [[HBDataSaveManager defaultManager] showEnBookName];
    NSString *wifiDownloadStr = [NSString stringWithFormat:@"%d", aWifiDownload];
    NSString *showEnBookNameStr = [NSString stringWithFormat:@"%d", aShowEnBookName];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:wifiDownloadStr, @"wifidownload", showEnBookNameStr, @"showenbookname", nil];
    
    [[HBDataSaveManager defaultManager] saveSettingsByDict:dict];
}

- (void)showEnglishName:(id)sender
{
    BOOL aShowEnBookName = YES;
    UISwitch *aSwitch = (UISwitch *)sender;
    if (aSwitch.isOn) {
        aShowEnBookName = YES;
    }else{
        aShowEnBookName = NO;
    }
    
    BOOL aWifiDownload = [[HBDataSaveManager defaultManager] wifiDownload];
    NSString *wifiDownloadStr = [NSString stringWithFormat:@"%d", aWifiDownload];
    NSString *showEnBookNameStr = [NSString stringWithFormat:@"%d", aShowEnBookName];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:wifiDownloadStr, @"wifidownload", showEnBookNameStr, @"showenbookname", nil];
    
    [[HBDataSaveManager defaultManager] saveSettingsByDict:dict];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSParameterAssert(_titleArr);
    return _titleArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(_titleArr);
    
    UITableViewCell *cell;
    
    if(indexPath.row == 0 || indexPath.row == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:KSettingViewControllerCellSwitchReuseId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:KSettingViewControllerCellSwitchReuseId];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [_titleArr objectAtIndex:indexPath.row];
        cell.textLabel.textColor = [UIColor blackColor];
        
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        
        if (indexPath.row == 0) {
            [switchView addTarget:self action:@selector(wifiDownload:) forControlEvents:UIControlEventValueChanged];
            if ([[HBDataSaveManager defaultManager] wifiDownload]) {
                [switchView setOn:YES];
            }else{
                [switchView setOn:NO];
            }
        }
        else{
            [switchView addTarget:self action:@selector(showEnglishName:) forControlEvents:UIControlEventValueChanged];
            if ([[HBDataSaveManager defaultManager] showEnBookName]) {
                [switchView setOn:YES];
            }else{
                [switchView setOn:NO];
            }
        }
        cell.accessoryView = switchView;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:KSettingViewControllerCellAccessoryReuseId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:KSettingViewControllerCellAccessoryReuseId];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [_titleArr objectAtIndex:indexPath.row];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; //显示最右边的箭头
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 2){
        HBBookManViewController *vc = [[HBBookManViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }else if (indexPath.row == 3){
        
    }else if (indexPath.row == 4){
        
    }else if (indexPath.row == 5){
        
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end