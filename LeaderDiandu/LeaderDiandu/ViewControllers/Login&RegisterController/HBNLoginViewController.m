//
//  HBNLoginViewController.m
//  LeaderDiandu
//
//  Created by xijun on 15/10/2.
//  Copyright (c) 2015年 hxj. All rights reserved.
//

#import "HBNLoginViewController.h"
#import "HBRegistViewController.h"
#import "HBForgetPwdViewController.h"

#import "NSString+Verify.h"
#import "HBServiceManager.h"

@interface HBNLoginViewController ()<UITextFieldDelegate>

@property(nonatomic, assign) BOOL isLoginChecking;

@property (nonatomic, strong) UITextField *inputPhoneNumber;
@property (nonatomic, strong) UITextField *inputPassword;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *userRegister;
@property (nonatomic, strong) UIButton *forgetPassword;

@end

@implementation HBNLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBarHidden = NO;
    self.title = @"登录";
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"注册" style:UIBarButtonItemStyleDone target:self action:@selector(userRegister:)];
    [rightButton setTintColor:[UIColor whiteColor]];
    self.navigationItem.rightBarButtonItem = rightButton;
    self.navigationItem.hidesBackButton = YES;
    
    [self initMainView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToHideKeyboard:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
}

- (void)tapToHideKeyboard:(id)sender
{
    [_inputPassword resignFirstResponder];
    [_inputPhoneNumber resignFirstResponder];
}

- (void)initMainView
{
    float controlY = KHBNaviBarHeight + 50;
    float screenW = self.view.frame.size.width;
    UIView *accountView = [[UIView alloc] initWithFrame:CGRectMake(0, controlY, screenW, 91)];
    accountView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:accountView];
    
    float controlX = 20;
    controlY = 0;
    float controlW = screenW - controlX;
    float controlH = 45;
    self.inputPhoneNumber = [[UITextField alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    _inputPhoneNumber.placeholder = @"手机号/ID";
    [accountView addSubview:_inputPhoneNumber];
    
    controlY += controlH;
    UILabel *lineLbl = [[UILabel alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, 1)];
    lineLbl.backgroundColor = RGBEQ(239);
    [accountView addSubview:lineLbl];
    
    controlY += 1;
    self.inputPassword = [[UITextField alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    _inputPassword.placeholder = @"输入密码";
    _inputPassword.secureTextEntry = YES;
    [accountView addSubview:_inputPassword];
    
    controlW = 100;
    controlH = 20;
    controlX = screenW - 20 - controlW;
    controlY = CGRectGetMaxY(accountView.frame) + 20;
    self.forgetPassword = [[UIButton alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    [_forgetPassword setTitle:@"忘记密码？" forState:UIControlStateNormal];
    _forgetPassword.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [_forgetPassword setTitleColor:RGBCOLOR(249, 156, 0) forState:UIControlStateNormal];
    [_forgetPassword addTarget:self action:@selector(forgetPassword:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_forgetPassword];
    
    controlX = 20;
    controlY = CGRectGetMaxY(_forgetPassword.frame) + 30;
    controlW = screenW - controlX*2;
    controlH = 45;
    self.loginButton = [[UIButton alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
    _loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_loginButton setBackgroundImage:[UIImage imageNamed:@"yellow-normal"] forState:UIControlStateNormal];
    [_loginButton setBackgroundImage:[UIImage imageNamed:@"yellow-press"] forState:UIControlStateHighlighted];
    [_loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loginButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Target Action
- (void)login:(id)sender
{
    [self tapToHideKeyboard:nil];
    
    NSString *phone = self.inputPhoneNumber.text;
    NSString *pwd = self.inputPassword.text;
    if ([NSString checkTextNULL:phone]  || [NSString checkTextNULL:pwd] ) {
        [MBHudUtil showTextView:@"请填写完整的用户名和密码" inView:nil];
        return;
    }
//    else if (![pwd isValidPassword]) {
//        [MBHudUtil showTextView:@"请输入正确格式的密码" inView:nil];
//    }
    
//    self.loginButton.enabled = NO;
    //登录
    [MBHudUtil showActivityView:nil inView:nil];
    [[HBServiceManager defaultManager] requestLogin:phone pwd:pwd completion:^(id responseObject, NSError *error) {
        [MBHudUtil hideActivityView:nil];
        if (error.code == 0) {
            //登录成功
            [[HBDataSaveManager defaultManager] loadFirstLogin];
            [[HBDataSaveManager defaultManager] saveFirstLogin];
            [[HBDataSaveManager defaultManager] loadSettings];
            
            self.loginButton.enabled = YES;
            [Navigator popToRootController];
            [[AppDelegate delegate] initDHSlideMenu];
            
            NSString *message = [NSString stringWithFormat:@"用户%@登录成功", phone];
            [MBHudUtil showTextViewAfter:message];
            
            //用户登录成功后发送通知
            [[NSNotificationCenter defaultCenter]postNotificationName:kNotification_LoginSuccess object:nil];
            
        } else {
            NSString *message = [NSString stringWithFormat:@"用户%@登录失败", phone];
            [MBHudUtil showTextViewAfter:message];
        }
    }];
}

- (void)loginWithQQ:(id)sender {
    //    [[MJLoginManager defaultManager] qqLogin];
}

- (void)loginWithWeibo:(id)sender {
    //    [[MJLoginManager defaultManager] weiboLogin];
}

- (void)forgetPassword:(id)sender
{
    HBForgetPwdViewController *vc = [[HBForgetPwdViewController alloc] init];
    vc.viewType = KLeaderViewTypeForgetPwd;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)userRegister:(id)sender
{
    HBForgetPwdViewController *vc = [[HBForgetPwdViewController alloc] init];
    vc.viewType = KLeaderViewTypeRegister;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Notification
//操作按钮的是否可用状态切换
- (void)setButton:(id)Sender Enable:(BOOL)isEnable
{
    UIButton *controlBtn = (UIButton *)Sender;
    controlBtn.enabled = isEnable;
    [controlBtn setBackgroundImage:[UIImage imageNamed:(isEnable?@"user_login_btn":@"user_login_btn2")] forState:UIControlStateNormal];
}

-(void)MJResignViewController_WillAppear
{
    [self addThirdLoginObserve];
}

- (void)addThirdLoginObserve
{
    [self removeThirdLoginObserve];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(receivedThirdLogin:) name:kNotificationWeiboLogin object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedThirdLogin:) name:kNotificationQQLogin object:nil];
}

- (void)removeThirdLoginObserve{
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationQQLogin object:nil];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationWeiboLogin object:nil];
}

- (void)receivedThirdLogin:(NSNotification *)notification
{
    [self loginedCheck];
}

- (void)loginedCheck
{
    if (_isLoginChecking) {
        return;
    }
    [self removeThirdLoginObserve];
    //判断是否已经绑定手机号
    
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.isLoginChecking = NO;
    return YES;
}

#pragma mark - PushPage
- (void)pushMenuPage{
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    //    MJMainViewController *mainVC = [[MJMainViewController alloc] initWithNibName:nil bundle:nil];
    //    [self.navigationController pushViewController:mainVC animated:YES];
}

#pragma mark - 控制旋转方向
-(NSUInteger)supportedInterfaceOrientations{
    //这里写你需要的方向
    return UIInterfaceOrientationPortrait;
}
- (BOOL)shouldAutorotate
{
    return NO;
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
