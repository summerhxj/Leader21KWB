//
//  HBGradeViewController.m
//  LeaderDiandu
//
//  Created by xijun on 15/8/26.
//  Copyright (c) 2015年 hxj. All rights reserved.
//

#import "HBGradeViewController.h"
#import "UIViewController+AddBackBtn.h"
#import "HBTitleView.h"
#import "DHSlideMenuController.h"
#import "HBGridView.h"
#import "TextGridItemView.h"
#import "HBDataSaveManager.h"
#import "HBServiceManager.h"
#import "HBContentManager.h"
#import "HBContentEntity.h"
#import "HBReadprogressEntity.h"
#import "HBContentListDB.h"
#import "HBReadProgressDB.h"
#import "FTMenu.h"
#import "Leader21SDKOC.h"
#import "CoreDataHelper.h"
#import "ReadBookViewController.h"
#import "HBTaskEntity.h"
#import "HBMyWorkViewController.h"
#import "LocalSettings.h"
#import "TimeIntervalUtils.h"
#import "HBTestWorkManager.h"
#import "HBPayViewController.h"
#import "HBSystemMsgEntity.h"
#import "HBMsgEntityDB.h"
#import "HBExamIdDB.h"

#define LEADERSDK [Leader21SDKOC sharedInstance]

#define DataSourceCount 10
#define saveReadProgress 0

@interface HBGradeViewController ()<HBGridViewDelegate, reloadGridDelegate>
{
    HBGridView *_gridView;
    NSInteger currentID;
    NSInteger subscribeId;
    NSString *readBookFromTime;
    NSString *readBookToTime;
}

@property (nonatomic, strong)NSMutableArray *contentEntityArr;
@property (nonatomic, strong)NSMutableDictionary *contentDetailEntityDic;
@property (nonatomic, strong)NSMutableDictionary *readProgressEntityDic;
@property (nonatomic, strong)NSMutableArray *taskEntityArr;

@property (nonatomic, strong)NSMutableDictionary *vipBookDic;

@property (nonatomic, strong)UIButton *leftButton;
@property (nonatomic, strong)UIButton *rightButton;

@property (nonatomic, strong)UIImageView *redPointImgView;

@end

@implementation HBGradeViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentEntityArr = [[NSMutableArray alloc] initWithCapacity:1];
        self.contentDetailEntityDic = [[NSMutableDictionary alloc] initWithCapacity:1];
        self.readProgressEntityDic = [[NSMutableDictionary alloc] initWithCapacity:1];
        self.taskEntityArr = [[NSMutableArray alloc] initWithCapacity:1];
        self.vipBookDic = [[NSMutableDictionary alloc] initWithCapacity:1];
        currentID = 1;
        subscribeId = -1;
        readBookFromTime = @"0";
        
        //用户登录成功通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LoginSuccess) name:kNotification_LoginSuccess object:nil];
        
        //用户阅读书籍返回通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ReadBookBack:) name:kNotification_ReadBookBack object:nil];
        
        //获取新消息列表成功通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getMsgSuccess) name:kNotification_GetMsgSuccess object:nil];
        
        //学生获取作业列表成功通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getExamSuccess) name:kNotification_GetExamSuccess object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)getMsgSuccess
{
    //有新消息或者新作业，显示红点，都没有则不显示
    if ([AppDelegate delegate].hasNewMsg || [AppDelegate delegate].hasNewExam) {
        [self.leftButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        self.redPointImgView.hidden = NO;
    }else{
        [self.leftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.redPointImgView.hidden = YES;
    }
}

-(void)getExamSuccess
{
    //有新消息或者新作业，显示红点，都没有则不显示
    if ([AppDelegate delegate].hasNewMsg || [AppDelegate delegate].hasNewExam) {
        [self.leftButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        self.redPointImgView.hidden = NO;
    }else{
        [self.leftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.redPointImgView.hidden = YES;
    }
}

-(void)LoginSuccess
{
    //用户是否首次登录(NO：首次登录 YES：非首次登录)
    BOOL notFirstLogin = [[HBDataSaveManager defaultManager] notFirstLogin];
    if (notFirstLogin) {
        //非首次登录，有新消息或者新作业显示红点
        [self requestSystemMsg];
    }else{
        //首次登录，不显示红点
    }

    [self.readProgressEntityDic removeAllObjects];
#if saveReadProgress
    //登录成功，先从本地读取一下当前用户数据库中保存的全部阅读进度
    self.readProgressEntityDic = [[HBReadProgressDB sharedInstance] getAllReadprogressDic];
#endif
    
    //只有学生有订阅等级，老师没有，初始化为-1
    subscribeId = -1;
    
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        /** type: 1 - 学生； 10 - 老师*/
        if (userEntity.type == 1) {
            [_gridView setHeaderViewHidden:NO];
            //获取用户当前订阅的套餐
            [[HBServiceManager defaultManager] requestUserBookset:userEntity.name token:userEntity.token completion:^(id responseObject, NSError *error) {
                if (responseObject) {
                    //获取用户当前订阅的套餐成功
                    id tmp = [responseObject objectForKey:@"bookset_id"];
                    subscribeId = [tmp integerValue];
                }
            }];
            //学生获取作业列表
            [self requestTaskListOfStudent];
            //从服务器拉取套餐信息
            [self requestAllBookset];
            //学生用户从服务器拉取最新的书籍阅读进度,老师用户直接从本地读取(本期老师不显示进度)
            NSString *user = userEntity.name;
            NSString *token = userEntity.token;
            [[HBServiceManager defaultManager] requestBookProgress:user token:token bookset_id:currentID completion:^(id responseObject, NSError *error) {
                if (responseObject) {
                    //获取阅读进度成功
                    [self requestBookProgressSuccess:responseObject];
                }
            }];
        }else{
            [_gridView setHeaderViewHidden:YES];
            //老师登录，将学生作业Id数组清空
            [self.taskEntityArr removeAllObjects];
            //登录成功先load套餐信息，如果套餐信息为空则去服务器拉取数据
            NSString *booksIDsStr = [[HBContentListDB sharedInstance] booksidWithID:currentID];
            if (booksIDsStr) {
                [self.contentEntityArr removeAllObjects];
                self.contentEntityArr = [[HBContentListDB sharedInstance] getAllContentEntitys];
                
                //根据套餐id返回该套餐对应的books字符串,转换为数组格式,便于操作
                NSArray *booksIDsArr=[booksIDsStr componentsSeparatedByString:@","];
                [self getContentDetailEntitys:booksIDsArr];
                
            }else{
                //从服务器拉取套餐信息
                [self requestAllBookset];
            }
        }
    }
}

-(void)ReadBookBack:(NSNotification*)note
{
    //记录一下结束阅读时间
    NSDate *date = [NSDate date];
    readBookToTime = [NSString stringWithFormat:@"%.f",[date timeIntervalSince1970]];
    
    NSMutableDictionary *dic = (NSMutableDictionary *)[note userInfo];
    NSString *bookId = [dic objectForKey:@"book_id"];
    NSString *progress = [dic objectForKey:@"progress"];
    
    if ([progress integerValue] == 100) {
        HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
        if (userEntity) {
            /** type: 1 - 学生； 10 - 老师*/
            if (userEntity.type == 1) {
                [self requestTaskListOfStudent];
            }
        }
    }
    
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        NSString *user = userEntity.name;
        NSString *token = userEntity.token;
        
        /** type: 1 - 学生； 10 - 老师*/
        if (userEntity.type == 1) {
            [MBHudUtil showActivityView:nil inView:nil];
            //上报用户读书行为
            [self bookReadingReport:userEntity bookInfoDic:dic];
            //学生上报一本书的阅读进度
            [[HBServiceManager defaultManager] requestUpdateBookProgress:user token:token book_id:[bookId integerValue] progress:[progress integerValue] completion:^(id responseObject, NSError *error) {
                [MBHudUtil hideActivityView:nil];
                NSString *book_id = [NSString stringWithFormat:@"%ld", [[responseObject objectForKey:@"book_id"] integerValue]];
                NSString *progress = [NSString stringWithFormat:@"%ld", [[responseObject objectForKey:@"progress"] integerValue]];
                NSString *exam_assigned = [responseObject objectForKey:@"exam_assigned"];
                
                HBReadprogressEntity *readprogressEntity = [self.readProgressEntityDic objectForKey:book_id];
                
                if (readprogressEntity) {
                    readprogressEntity.progress = progress;
                    readprogressEntity.exam_assigned = exam_assigned;
                }else{
                    readprogressEntity = [[HBReadprogressEntity alloc] init];
                    readprogressEntity.book_id = book_id;
                    readprogressEntity.progress = progress;
                    readprogressEntity.exam_assigned = NO; //先临时设置为NO
                    [self.readProgressEntityDic setObject:readprogressEntity forKey:book_id];
                }
                
#if saveReadProgress
                NSMutableArray *progressArr = [[NSMutableArray alloc] initWithCapacity:1];
                [progressArr addObject:readprogressEntity];
                
                [[HBReadProgressDB sharedInstance] updateHBReadprogress:progressArr];
#endif
                
                [self reloadGrid];
            }];
        }else{
#if saveReadProgress
            HBReadprogressEntity *readprogressEntity = [self.readProgressEntityDic objectForKey:bookId];
            
            if (readprogressEntity) {
                readprogressEntity.progress = progress;
                readprogressEntity.exam_assigned = NO; //先临时设置为NO
            }else{
                readprogressEntity = [[HBReadprogressEntity alloc] init];
                readprogressEntity.book_id = bookId;
                readprogressEntity.progress = progress;
                readprogressEntity.exam_assigned = NO; //先临时设置为NO
                [self.readProgressEntityDic setObject:readprogressEntity forKey:bookId];
            }
            
            NSMutableArray *progressArr = [[NSMutableArray alloc] initWithCapacity:1];
            [progressArr addObject:readprogressEntity];
            
            [[HBReadProgressDB sharedInstance] updateHBReadprogress:progressArr];
            
            [self reloadGrid];
#endif
        }
    }
}

-(void)bookReadingReport:(HBUserEntity *)userEntity bookInfoDic:(NSMutableDictionary *)dic
{
    NSString *bookId = [dic objectForKey:@"book_id"];
    NSString *toPage = [dic objectForKey:@"toPage"];
    NSString *totalPage = [dic objectForKey:@"totalPage"];
    
    [[HBServiceManager defaultManager] requestReportBookProgress:userEntity.name token:userEntity.token book_id:[bookId integerValue] bookset_id:currentID from_time:readBookFromTime to_time:readBookToTime from_page:@"1" to_page:toPage total_page:totalPage completion:^(id responseObject, NSError *error) {
        //上报用户读书行为成功！！！
    }];
}

-(void)requestBookProgressSuccess:(id)responseObject
{
    NSArray *arr = [responseObject objectForKey:@"progress"];
    for (NSDictionary *dict in arr)
    {
        NSString *book_id = [NSString stringWithFormat:@"%ld", [[dict objectForKey:@"id"] integerValue]];
        NSString *progress = [NSString stringWithFormat:@"%ld", [[dict objectForKey:@"progress"] integerValue]];
        
        HBReadprogressEntity *readprogressEntity = [self.readProgressEntityDic objectForKey:book_id];
        
        if (readprogressEntity) {
            readprogressEntity.progress = progress;
        }else{
            readprogressEntity = [[HBReadprogressEntity alloc] init];
            readprogressEntity.book_id = book_id;
            readprogressEntity.progress = progress;
            readprogressEntity.exam_assigned = NO; //先临时设置为NO
            [self.readProgressEntityDic setObject:readprogressEntity forKey:book_id];
        }
    }
    
#if saveReadProgress
    NSArray* keys = [self.readProgressEntityDic allKeys];
    NSMutableArray *progressArr = [[NSMutableArray alloc] initWithCapacity:1];
    for(NSString* str in keys)
    {
        [progressArr addObject:[self.readProgressEntityDic objectForKey:str]];
    }
    [[HBReadProgressDB sharedInstance] updateHBReadprogress:progressArr];
#endif
    
    [self reloadGrid];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [LEADERSDK setAppKey:KAppKeyStudy];
    
    CGRect rect = self.view.frame;
    UIImageView *navView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(rect), KHBNaviBarHeight)];
    navView.image = [UIImage imageNamed:@"bookshelf-bg-navi"];
    [self.view addSubview:navView];
    
    [self initMainView];
    [self initMainGrid];
    [self initButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
//    //token失效后再进来需要重新获取数据
//    if ([self.contentEntityArr count] == 0) {
//        //获取所有可选套餐
//        [self requestAllBookset];
//    }

    [self reloadGrid];
}

-(void)getContentDetailEntitys:(NSArray *)booksIDsArr
{
    NSMutableArray *booklist = [[NSMutableArray alloc] initWithCapacity:1];
    for (NSString *bookId in booksIDsArr) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"bookId == %@", bookId];
        BookEntity *bookEntity = (BookEntity*)[CoreDataHelper getFirstObjectWithEntryName:@"BookEntity" withPredicate:predicate];
        if (bookEntity != nil) {
            [booklist addObject:bookEntity];
        }else{
            //获取书本列表
            [self requestContentDetailEntity];
            return ;
        }
    }
    [self.contentDetailEntityDic removeAllObjects];
    [self.contentDetailEntityDic setObject:booklist forKey:[NSString stringWithFormat:@"%ld", (long)currentID]];
    
    //筛选出free和vip的书籍 1:vip 0:free
    HBContentEntity *contentEntity = [self.contentEntityArr objectAtIndex:currentID - 1];
    NSArray *freeBooksArr = [contentEntity.free_books componentsSeparatedByString:@","];
    [self.vipBookDic removeAllObjects];
    for (BookEntity *bookEntity in booklist) {
        if ([freeBooksArr containsObject:[NSString stringWithFormat:@"%@", bookEntity.bookId]]) {
            [self.vipBookDic setObject:@"0" forKey:bookEntity.bookId];
        }else{
            [self.vipBookDic setObject:@"1" forKey:bookEntity.bookId];
        }
    }
    
    [_gridView hideRefreshView];
    [self reloadGrid];
}

- (void)initMainView
{
    HBTitleView *labTitle = [HBTitleView titleViewWithTitle:@"课外宝" onView:self.view];
    labTitle.textColor = [UIColor blackColor];
    [self.view addSubview:labTitle];
}

- (void)initMainGrid
{
    if (_gridView == nil) {
        _gridView = [[HBGridView alloc] initWithFrame:CGRectMake(0, KHBNaviBarHeight, ScreenWidth, ScreenHeight - KHBNaviBarHeight)];
        _gridView.delegate = self;
        _gridView.backgroundColor = [UIColor clearColor];
        [_gridView setBackgroundView:@"bookshelf-bg-body"];
        
        HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
        if (userEntity) {
            /** type: 1 - 学生； 10 - 老师*/
            if (userEntity.type == 1) {
                [_gridView setHeaderViewHidden:NO];
            }else{
                [_gridView setHeaderViewHidden:YES];
            }
        }

        [self.view addSubview:_gridView];
    }
}

-(void)showPullView
{
    NSMutableArray *menuItems = [[NSMutableArray alloc] initWithCapacity:1];
    
    for (HBContentEntity *contentEntity in self.contentEntityArr) {
        NSString * bookIdStr = [NSString stringWithFormat:@"%ld", contentEntity.bookId];
        KxMenuItem *item = [KxMenuItem
                            menuItem:bookIdStr
                            image:nil
                            target:self
                            action:@selector(pushMenuItem:)];
        [menuItems addObject:item];
    }

    CGRect menuFrame = CGRectMake(ScreenWidth - 70, 70, 60, 50 * self.contentEntityArr.count);

    [FTMenu showMenuWithFrame:menuFrame inView:self.navigationController.view menuItems:menuItems currentID:subscribeId];
}

- (void) pushMenuItem:(KxMenuItem *)sender
{
    currentID = [sender.title integerValue];
    
    [self.rightButton setTitle:sender.title forState:UIControlStateNormal];
    [self.rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    //获取书本列表
    for (HBContentEntity *contentEntity in self.contentEntityArr) {
        if (contentEntity.bookId == currentID) {
            //根据套餐id返回该套餐对应的books字符串,转换为数组格式,便于操作
            NSMutableArray *books = (NSMutableArray *)[contentEntity.books componentsSeparatedByString:@","];
            NSArray *assigned_books = [contentEntity.assigned_books componentsSeparatedByString:@","];
            for (NSString * content in assigned_books) {
                [books addObject:content];
            }
            NSSet *set = [NSSet setWithArray:(NSArray *)books];
            
            NSMutableArray *sortArray = [[NSMutableArray alloc] initWithCapacity:1];
            for (NSString * str in set) {
                [sortArray addObject:str];
            }
            
            NSArray *destArr = [sortArray sortedArrayUsingComparator:cmptr];
            
            [self getContentDetailEntitys:destArr];
        }
    }
    
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        /** type: 1 - 学生； 10 - 老师*/
        if (userEntity.type == 1) {
            //学生用户从服务器拉取最新的书籍阅读进度,老师用户直接从本地读取(本期老师不显示进度)
            NSString *user = userEntity.name;
            NSString *token = userEntity.token;
            [[HBServiceManager defaultManager] requestBookProgress:user token:token bookset_id:currentID completion:^(id responseObject, NSError *error) {
                if (responseObject) {
                    //获取阅读进度成功
                    [self requestBookProgressSuccess:responseObject];
                }
            }];
        }
    }
}

- (void)initButton
{
    self.leftButton = [[UIButton alloc] initWithFrame:CGRectMake(8, 20, 44, 44)];
    [self.leftButton setBackgroundImage:[UIImage imageNamed:@"bookshelf-btn-menu"] forState:UIControlStateNormal];
    [self.leftButton addTarget:self action:@selector(ToggleMenuPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.leftButton];
    
    self.redPointImgView = [[UIImageView alloc] initWithFrame:CGRectMake(44 - 15, 5, 15, 15)];
    self.redPointImgView.image = [UIImage imageNamed:@"msg_tips_new"];
    self.redPointImgView.hidden = YES;
    [self.leftButton addSubview:self.redPointImgView];
    
    self.rightButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - 8 - 44, 20, 44, 44)];
    [self.rightButton setBackgroundImage:[UIImage imageNamed:@"bookshelf-btn-class"] forState:UIControlStateNormal];
    [self.rightButton addTarget:self action:@selector(rightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.rightButton setTitle:@"1" forState:UIControlStateNormal];
    [self.rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:self.rightButton];
}

- (void)ToggleMenuPressed:(id)sender
{
    [[DHSlideMenuController sharedInstance] showLeftViewController:YES];
}

- (void)rightButtonPressed:(id)sender
{
    [self showPullView];
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

#pragma mark -
#pragma mark HBGridViewDelegate

// 获取单元格的总数
- (NSInteger)gridNumberOfGridView:(HBGridView *)gridView
{
    NSMutableArray *arr = [self.contentDetailEntityDic objectForKey:[NSString stringWithFormat:@"%ld", currentID]];
    return arr.count;
}

// 获取gridview每行显示的grid数
- (NSInteger)columnNumberOfGridView:(HBGridView *)gridView
{
    return 3;
}

// 获取单元格的行数
- (NSInteger)rowNumberOfGridView:(HBGridView *)gridView
{
    NSMutableArray *arr = [self.contentDetailEntityDic objectForKey:[NSString stringWithFormat:@"%ld", currentID]];
    
    if (arr.count % [self columnNumberOfGridView:gridView])
    {
        return arr.count / [self columnNumberOfGridView:gridView] + 1;
    }
    else
    {
        return arr.count / [self columnNumberOfGridView:gridView];
    }
}

- (CGFloat)gridView:(HBGridView *)gridView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (ScreenHeight - KHBNaviBarHeight) / 3.0f;
}

// 获取特定位置的单元格视图
- (HBGridItemView *)gridView:(HBGridView *)gridView inGridCell:(HBGridCellView *)gridCell gridItemViewAtGridIndex:(GridIndex *)gridIndex listIndex:(NSInteger)listIndex
{
    NSLog(@"list index:%ld", (long)listIndex);
    TextGridItemView *itemView = (TextGridItemView *)[gridView dequeueReusableGridItemAtGridIndex:gridIndex ofGridCellView:gridCell];
    if (!itemView)
    {
        itemView = [[TextGridItemView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth/3, (ScreenHeight - KHBNaviBarHeight)/3)];
    }
    
    itemView.delegate = self;
    
    NSMutableArray *arr = [self.contentDetailEntityDic objectForKey:[NSString stringWithFormat:@"%ld", (long)currentID]];
    BookEntity *entity = arr[listIndex];
    NSString *bookTitle = entity.bookTitleCN;
    if ([[HBDataSaveManager defaultManager] showEnBookName]) {
        bookTitle = entity.bookTitle;
    }
    
    NSDictionary * targetData = [[NSDictionary alloc]initWithObjectsAndKeys:
                                 bookTitle, TextGridItemView_BookName,entity.fileId, TextGridItemView_BookCover, @"mainGrid_download", TextGridItemView_downloadState, [self.vipBookDic objectForKey:entity.bookId], TextGridItemView_isVip, nil];

    [itemView updateFormData:targetData];
    
    itemView.bookDownloadUrl = entity.bookUrl;
    
    NSString *book_id = [NSString stringWithFormat:@"%@", entity.bookId];
    HBReadprogressEntity *readprogressEntity = [self.readProgressEntityDic objectForKey:book_id];
    NSString *progress = readprogressEntity.progress;
    
    if ([LEADERSDK isBookDownloaded:entity]) {
        HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
        if (userEntity) {
            /** type: 1 - 学生； 10 - 老师*/
            if (userEntity.type == 1) {
                //已下载（阅读完成,并且在作业列表里面，显示“作业”；阅读完成,不在作业列表里面显示“100%”；阅读未完成显示进度条）
                BOOL flag = YES;
                for (HBTaskEntity *taskentity in self.taskEntityArr) {
                    if (taskentity.bookId == [entity.bookId integerValue]) {
                        [itemView bookDownloaded:entity progress:progress isTask:YES];
                        flag = NO;
                        break;
                    }
                }
                if (flag) {
                    [itemView bookDownloaded:entity progress:progress isTask:NO];
                }
            }else{
                [itemView teacherBookDownloaded:entity];
            }
        }
    }else if([LEADERSDK isBookDownloading:entity]){
        [itemView bookDownloading:entity];  //正在下载
    }else{
        [itemView bookUnDownload:entity];   //未下载
    }
    
    return itemView;
}

- (void)gridView:(HBGridView *)gridView didSelectGridItemAtIndex:(NSInteger)index
{
    TextGridItemView *itemView = (TextGridItemView *)[gridView gridItemViewAtIndex:index];
//    itemView.backgroundColor = [UIColor grayColor];
    
    NSMutableArray *arr = [self.contentDetailEntityDic objectForKey:[NSString stringWithFormat:@"%ld", (long)currentID]];

    BookEntity *entity = arr[index];
    
    //VIP书籍，需要提示用户
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        /** type: 1 - 学生； 10 - 老师*/
        if (userEntity.type == 1) {
            if ([[self.vipBookDic objectForKey:entity.bookId] isEqualToString:@"1"]) {
                if (userEntity.account_status == 1) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"你尚未开通VIP，无权下载阅读此书，请开通VIP后再试。" delegate:self cancelButtonTitle:@"再等等" otherButtonTitles:@"现在激活", nil];
                    alertView.tag = 0;
                    
                    [alertView show];
                    
                    return;
                }else if(userEntity.account_status == 3){
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"你的VIP已过期，无权下载阅读此书，请重新激活后再试。" delegate:self cancelButtonTitle:@"再等等" otherButtonTitles:@"现在激活", nil];
                    alertView.tag = 0;
                    
                    [alertView show];
                    
                    return;
                }
            }
        }
    }
    
    if([LEADERSDK isBookDownloading:entity]){
        //正在下载，不处理
    }else{
        if (itemView.isTest) {
            //跳转作业逻辑
            [self jumpToTestWork:[entity.bookId integerValue]];
        } else {
            //记录一下开始阅读时间
            NSDate *date = [NSDate date];
            readBookFromTime = [NSString stringWithFormat:@"%.f",[date timeIntervalSince1970]];
            
            [LEADERSDK bookPressed:entity useNavigation:[AppDelegate delegate].globalNavi];
            itemView.bookDownloadUrl = entity.bookUrl;
        }
    }
}

#pragma mark - actionSheetDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        
    }else{
        HBPayViewController *controller = [[HBPayViewController alloc] init];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

#pragma mark --跳转作业逻辑--

- (void)jumpToTestWork:(NSInteger)bookId
{
    HBTaskEntity *taskEntity = nil;
    for (taskEntity in _taskEntityArr) {
        if (taskEntity.bookId == bookId) {
            break;
        }
    }
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        NSString *user = userEntity.name;
        [MBHudUtil showActivityView:nil inView:nil];
        [[HBServiceManager defaultManager] requestBookInfo:user book_id:bookId completion:^(id responseObject, NSError *error) {
            // to do ...
            if (responseObject) {
                NSDictionary *dict = responseObject;
                if (dict == nil) {
                    [MBHudUtil hideActivityView:nil];
                    [MBHudUtil showTextViewAfter:@"服务器资源缺失，敬请期待"];
                } else {
                    NSString *url = dict[@"url"];
                    [self downloadTestWork:url onSelect:taskEntity];
                }
            }
        }];
    }
}

- (void)downloadTestWork:(NSString *)url onSelect:(HBTaskEntity *)taskEntity
{
    NSString *path = [LocalSettings bookCachePath];
    path = [NSString stringWithFormat:@"%@/%@", path, KHBTestWorkPath];
    [[HBContentManager defaultManager] downloadFileURL:url savePath:path fileName:@"test.zip" completion:^(id responseObject, NSError *error) {
        [MBHudUtil hideActivityView:nil];
        if (responseObject && [responseObject isKindOfClass:[NSString class]]) {
            NSString *path = responseObject;
            HBTestWorkManager *workManager = [[HBTestWorkManager alloc] init];
            [workManager parseTestWork:path];
            HBMyWorkViewController *controller = [[HBMyWorkViewController alloc] init];
            controller.workManager = workManager;
            controller.taskEntity = taskEntity;
            [self.navigationController pushViewController:controller animated:YES];
        } else {
            [MBHudUtil showTextViewAfter:@"服务器资源缺失，敬请期待"];
        }
    }];
}

-(void)refreshTableHeaderDidTriggerRefresh
{
    //下拉加载 加载数据 (从服务器拉取套餐信息）
//    [self requestAllBookset];
    
    [self LoginSuccess];
}

- (void)requestAllBookset
{
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        NSString *user = userEntity.name;
        NSString *token = userEntity.token;
        //获取所有可选套餐
        [[HBServiceManager defaultManager] requestAllBookset:user token:token completion:^(id responseObject, NSError *error) {
            if (responseObject) {
                //获取所有可选套餐成功
                [self.contentEntityArr removeAllObjects];
                NSArray *arr = [responseObject objectForKey:@"booksets"];
                for (NSDictionary *dict in arr)
                {
                    HBContentEntity *contentEntity = [[HBContentEntity alloc] initWithDictionary:dict];
                    [self.contentEntityArr addObject:contentEntity];
                }

                /** type: 1 - 学生； 10 - 老师*/
                if (userEntity.type == 1) {
                    //获取书本列表
                    for (HBContentEntity *contentEntity in self.contentEntityArr) {
                        if (contentEntity.bookId == currentID) {
                            //根据套餐id返回该套餐对应的books字符串,转换为数组格式,便于操作
                            NSMutableArray *books = (NSMutableArray *)[contentEntity.books componentsSeparatedByString:@","];
                            NSArray *assigned_books = [contentEntity.assigned_books componentsSeparatedByString:@","];
                            for (NSString * content in assigned_books) {
                                [books addObject:content];
                            }
                            NSSet *set = [NSSet setWithArray:(NSArray *)books];
                            
                            NSMutableArray *sortArray = [[NSMutableArray alloc] initWithCapacity:1];
                            for (NSString * str in set) {
                                [sortArray addObject:str];
                            }
                            
                            NSArray *destArr = [sortArray sortedArrayUsingComparator:cmptr];
                            
                            [self getContentDetailEntitys:destArr];
                        }
                    }
                } else {
                    //老师获取所有可选套餐成功保存数据库
                    [[HBContentListDB sharedInstance] updateHBContentList:arr];
                    //获取书本列表
                    [self requestContentDetailEntity];
                }
            }
        }];
    }
}

-(void)requestContentDetailEntity
{
    //获取书本列表
    for (HBContentEntity *contentEntity in self.contentEntityArr) {
        if (contentEntity.bookId == currentID) {
            
            NSMutableArray *books = (NSMutableArray *)[contentEntity.books componentsSeparatedByString:@","];
            NSArray *assigned_books = [contentEntity.assigned_books componentsSeparatedByString:@","];
            for (NSString * content in assigned_books) {
                [books addObject:content];
            }
            NSSet *set = [NSSet setWithArray:(NSArray *)books];
            
            NSMutableArray *sortArray = [[NSMutableArray alloc] initWithCapacity:1];
            for (NSString * str in set) {
                [sortArray addObject:str];
            }
            
            NSArray *destArr = [sortArray sortedArrayUsingComparator:cmptr];
            
            NSString *destBooksStr = [destArr componentsJoinedByString:@","];

            [LEADERSDK requestBookInfo:destBooksStr onComplete:^(NSArray *booklist, NSInteger errorCode, NSString *errorMsg) {
                
                NSMutableArray *booklistTmp = [[NSMutableArray alloc] initWithCapacity:1];
                for (BookEntity *entityTmp in booklist) {
                    [booklistTmp addObject:entityTmp];
                }
                
                //如果缓存中有数据，先不要清空，可能这个时候缓存中的数据保存着正在下载书籍的URL等信息
                if (self.contentDetailEntityDic.count > 0) {
                    NSMutableArray *arr = [self.contentDetailEntityDic objectForKey:[NSString stringWithFormat:@"%ld", currentID]];
                    
                    for (BookEntity *entity in arr) {
                        for (NSInteger index = 0; index < booklistTmp.count; index++) {
                            BookEntity *newEntity = [booklistTmp objectAtIndex:index];
                            if ([entity.fileId isEqualToString:newEntity.fileId]) {
                                [booklistTmp replaceObjectAtIndex:index withObject:entity];
                                break;
                            }
                        }
                    }
                }
                
                [self.contentDetailEntityDic removeAllObjects];
                [self.contentDetailEntityDic setObject:booklistTmp forKey:[NSString stringWithFormat:@"%ld", (long)currentID]];
                
                //筛选出free和vip的书籍 1:vip 0:free
                HBContentEntity *contentEntity = [self.contentEntityArr objectAtIndex:currentID - 1];
                NSArray *freeBooksArr = [contentEntity.free_books componentsSeparatedByString:@","];
                [self.vipBookDic removeAllObjects];
                for (BookEntity *bookEntity in booklist) {
                    if ([freeBooksArr containsObject:[NSString stringWithFormat:@"%@", bookEntity.bookId]]) {
                        [self.vipBookDic setObject:@"0" forKey:bookEntity.bookId];
                    }else{
                        [self.vipBookDic setObject:@"1" forKey:bookEntity.bookId];
                    }
                }
                
                [_gridView hideRefreshView];
                [self reloadGrid];
            }];
            
            break;
        }
    }
}

-(void)reloadGridView
{
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        /** type: 1 - 学生； 10 - 老师*/
        if (userEntity.type == 1) {
            [self requestTaskListOfStudent];
        }
    }
    [self reloadGrid];
}

-(void)reloadGrid
{
    [_gridView reloadData];
}

-(void)requestTaskListOfStudent
{
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    if (userEntity) {
        NSString *user = userEntity.name;
        [[HBServiceManager defaultManager] requestTaskListOfStudent:user from:0 count:100 completion:^(id responseObject, NSError *error) {
            if (responseObject) {
                //学生获取作业列表成功
                [self.taskEntityArr removeAllObjects];
                NSArray *arr = [responseObject objectForKey:@"exams"];
                for (NSDictionary *dic in arr)
                {
                    HBTaskEntity *taskEntity = [[HBTaskEntity alloc] init];
                    taskEntity.exam_id = [[dic numberForKey:@"exam_id"] integerValue];
                    
                    NSDictionary *teacherDic = [dic dicForKey:@"teacher"];
                    NSString *teacherName = [teacherDic stringForKey:@"display_name"];
                    if ([teacherName length] == 0) {
                        teacherName = [teacherDic stringForKey:@"name"];
                    }
                    taskEntity.teacherName = teacherName;
                    
                    NSDictionary *bookDic = [dic dicForKey:@"book"];
                    NSString *bookName;
                    if ([[HBDataSaveManager defaultManager] showEnBookName]) {
                        bookName = [bookDic stringForKey:@"book_title"];
                    }else{
                        bookName = [bookDic stringForKey:@"book_title_cn"];
                    }
                    taskEntity.bookId = [[bookDic numberForKey:@"id"] integerValue];
                    taskEntity.bookName = bookName;
                    taskEntity.fileId = [bookDic stringForKey:@"file_id"];
                    
                    NSTimeInterval interval = [[dic numberForKey:@"created_time"] doubleValue];
                    taskEntity.createdTime = [TimeIntervalUtils getStringMDHMSFromTimeInterval:interval];
                    interval = [[dic numberForKey:@"modified_time"] doubleValue];
                    taskEntity.modifiedTime = [TimeIntervalUtils getStringMDHMSFromTimeInterval:interval];
                    taskEntity.score = [dic stringForKey:@"score"];
                    
                    [self.taskEntityArr addObject:taskEntity];
                }
                
                [self reloadGrid];
                
                //用户是否首次登录(NO：首次登录 YES：非首次登录)
                BOOL notFirstLogin = [[HBDataSaveManager defaultManager] notFirstLogin];
                if (notFirstLogin) {    //非首次登录，有新消息或者新作业显示红点
                    //从数据库获取所有作业ID
                    NSMutableArray *examIdArr = [[HBExamIdDB sharedInstance] getAllExamId];
                    NSString *localMaxExamId = @"";
                    NSString *newMaxExamId = @"";
                    
                    if (examIdArr.count > 0) {
                        NSArray *destArr = [examIdArr sortedArrayUsingComparator:cmptr];
                        localMaxExamId = [destArr objectAtIndex:destArr.count - 1];
                    }
                    
                    if (self.taskEntityArr.count > 0) {
                        HBTaskEntity *taskEntity = [self.taskEntityArr objectAtIndex:0];
                        newMaxExamId = [NSString stringWithFormat:@"%ld", taskEntity.exam_id];
                    }
                    
                    //如果新的作业ID值大于数据库中保存的最大作业ID值，则说明有新作业，需要显示红点
                    if ([newMaxExamId integerValue] > [localMaxExamId integerValue]) {
                        [AppDelegate delegate].hasNewExam = YES;
                    }else{
                        [AppDelegate delegate].hasNewExam = NO;
                    }
                    
                    //学生获取作业列表成功后发送通知
                    [[NSNotificationCenter defaultCenter]postNotificationName:kNotification_GetExamSuccess object:nil];
                }else{
                    //首次登录，不显示红点
                }
            }
        }];
    }
}

-(void)requestSystemMsg
{
    HBUserEntity *userEntity = [[HBDataSaveManager defaultManager] userEntity];
    //1443248966 是临时用来测试的时间，后续需要改成正式的！
    [[HBServiceManager defaultManager] requestSystemMsg:userEntity.name token:userEntity.token from_time:@"1443248966" completion:^(id responseObject, NSError *error) {
        if (responseObject) {
            
            //从数据库读取本地所有消息内容
            NSMutableArray *localMsgArr = [[HBMsgEntityDB sharedInstance] getAllMsgEntity];
            NSString *localMaxMsgId = @"";
            NSString *newMaxMsgId = @"";
            if (localMsgArr.count > 0) {
                HBSystemMsgEntity *msgEntity = [localMsgArr objectAtIndex:0];
                localMaxMsgId = msgEntity.systemMsgId;
            }
            
            NSArray *array = [responseObject arrayForKey:@"messages"];
            for (NSDictionary *dic in array)
            {
                newMaxMsgId = [NSString stringWithFormat:@"%ld", [dic integerForKey:@"id"]];
                break;
            }
            
            //如果新的消息ID值大于数据库中保存的最大消息ID值，则说明有新消息，需要显示红点
            if ([newMaxMsgId integerValue] > [localMaxMsgId integerValue]) {
                [AppDelegate delegate].hasNewMsg = YES;
            }else{
                [AppDelegate delegate].hasNewMsg = NO;
            }
            
            //获取新消息列表成功后发送通知
            [[NSNotificationCenter defaultCenter]postNotificationName:kNotification_GetMsgSuccess object:nil];
        }
    }];
}

NSComparator cmptr = ^(id obj1, id obj2){
    if ([obj1 integerValue] > [obj2 integerValue]) {
        return (NSComparisonResult)NSOrderedDescending;
    }
    
    if ([obj1 integerValue] < [obj2 integerValue]) {
        return (NSComparisonResult)NSOrderedAscending;
    }
    return (NSComparisonResult)NSOrderedSame;
};

@end
