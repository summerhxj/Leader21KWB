//
//  HBTestWorkViewController.m
//  LeaderDiandu
//
//  Created by xijun on 15/9/1.
//  Copyright (c) 2015年 hxj. All rights reserved.
//

#import "HBTestWorkViewController.h"
#import "UIViewController+AddBackBtn.h"
#import "HBTitleView.h"
#import "HBDataSaveManager.h"
#import "HBServiceManager.h"
#import "HBTaskEntity.h"
#import "TimeIntervalUtils.h"

static NSString * const KTestWorkViewControllerCellReuseId = @"KTestWorkViewControllerCellReuseId";

@implementation HBTestWorkViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initUI];
    }
    return self;
}

- (void) initUI
{
    //时间
    self.cellTime = [[UILabel alloc] init];
    self.cellTime.frame = CGRectMake(10, 5, 120, 25);
    [self addSubview:self.cellTime];
    
    //老师
    self.cellTeacherName = [[UILabel alloc] init];
    self.cellTeacherName.frame = CGRectMake(self.cellTime.frame.origin.x + self.cellTime.frame.size.width + 10, 5, 80, 25);
    [self addSubview:self.cellTeacherName];
    
    //分数
    self.cellScore = [[UILabel alloc] init];
    self.cellScore.frame = CGRectMake(ScreenWidth - 100, 5, 100, 25);
    [self addSubview:self.cellScore];
    
    //书皮
    self.cellImageBookCover = [[UIImageView alloc] init];
    self.cellImageBookCover.image = [UIImage imageNamed:@"mainGrid_defaultBookCover"];
    self.cellImageBookCover.frame = CGRectMake(10, 35, 50, 60);
    [self addSubview:self.cellImageBookCover];
    
    //书名
    self.cellBookName = [[UILabel alloc] init];
    self.cellBookName.frame = CGRectMake(self.cellImageBookCover.frame.origin.x + self.cellImageBookCover.frame.size.width + 10, 35, 200, 60);
    [self addSubview:self.cellBookName];
    
    //状态
    self.cellSubmitState = [[UILabel alloc] init];
    self.cellSubmitState.frame = CGRectMake(ScreenWidth - 100, 35, 100, 60);
    [self addSubview:self.cellSubmitState];
}

-(void)updateFormData:(id)sender
{
    HBTaskEntity *taskEntity = (HBTaskEntity*)sender;
    
    if (taskEntity) {
        self.cellTime.text = taskEntity.taskTime;
        self.cellTeacherName.text = taskEntity.teacherName;
        self.cellScore.text = taskEntity.score;
        self.cellBookName.text = taskEntity.bookName;
        if (taskEntity.score) {
            self.cellSubmitState.text = @"已提交";
        }else{
            self.cellSubmitState.text = @"未提交";
        }
    }
    //刷新cell
//    [self setNeedsLayout];
}

@end

@interface HBTestWorkViewController ()<UITableViewDataSource, UITableViewDelegate>
{
    UITableView *_tableView;
}

@property (nonatomic, strong)NSMutableArray *taskEntityArr;

@end

@implementation HBTestWorkViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.taskEntityArr = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    HBTitleView *labTitle = [HBTitleView titleViewWithTitle:@"测试作业" onView:self.view];
    [self.view addSubview:labTitle];
    
    [self addBackButton];
    [self requestTaskListOfStudent];
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

-(void)addTableView
{
    CGRect rect = self.view.frame;
    CGRect viewFrame = CGRectMake(0, KHBNaviBarHeight, rect.size.width, rect.size.height-KHBNaviBarHeight);
    _tableView = [[UITableView alloc] initWithFrame:viewFrame];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

-(void)requestTaskListOfStudent
{
    NSDictionary *dict = [[HBDataSaveManager defaultManager] loadUser];
    if (dict) {
        NSString *user = [dict objectForKey:@"name"];
//        NSString *timeStr = [NSString stringWithFormat:@"%f", [NSDate date].timeIntervalSince1970];
        [[HBServiceManager defaultManager] requestTaskListOfStudent:user from:0 count:10 completion:^(id responseObject, NSError *error) {
            
            if (responseObject) {
                //学生获取作业列表成功
                NSArray *arr = [responseObject objectForKey:@"exams"];
                for (NSDictionary *dic in arr)
                {
                    HBTaskEntity *taskEntity = [[HBTaskEntity alloc] init];
                    
                    NSDictionary *teacherDic = [dic objectForKey:@"teacher"];
                    NSString *teacherName = [teacherDic objectForKey:@"display_name"];
                    taskEntity.teacherName = teacherName;
                    
                    NSDictionary *bookDic = [dic objectForKey:@"book"];
                    NSString *bookName = [bookDic objectForKey:@"book_title_cn"];
                    taskEntity.bookName = bookName;
                    
                    NSTimeInterval interval = [[dic objectForKey:@"modified_time"] doubleValue];
                    taskEntity.taskTime = [TimeIntervalUtils getStringMDHMSFromTimeInterval:interval];
                    
                    NSString *score = [dic objectForKey:@"score"];
                    if ([score isKindOfClass:[NSNull class]] || score == nil) {
                        taskEntity.score = @"";
                    } else {
                        taskEntity.score = score;
                    }
                    
                    [self.taskEntityArr addObject:taskEntity];
                }
                if (self.taskEntityArr.count > 0) {
                    [self addTableView];
                }
            }
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSParameterAssert(self.taskEntityArr);
    return self.taskEntityArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(self.taskEntityArr);

    HBTestWorkViewCell *cell = [tableView dequeueReusableCellWithIdentifier:KTestWorkViewControllerCellReuseId];
    if (!cell) {
        cell = [[HBTestWorkViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:KTestWorkViewControllerCellReuseId];
    }
    
    HBTaskEntity *taskEntity = [self.taskEntityArr objectAtIndex:indexPath.row];
    [cell updateFormData:taskEntity];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; //显示最右边的箭头

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
