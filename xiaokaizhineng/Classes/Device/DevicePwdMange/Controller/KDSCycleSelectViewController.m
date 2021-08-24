//
//  KDSCycleSelectViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/14.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSCycleSelectViewController.h"
#import "KDSWeekDaySelectTableViewCell.h"
#import "KDSEverydayView.h"
#import "UIView+BlockGesture.h"

@interface KDSCycleSelectViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<NSIndexPath *> *selectArr;
@property (nonatomic, strong)KDSEverydayView *everydayView;
@property (nonatomic, strong)NSArray *dataArray;
@property (nonatomic, strong)NSMutableArray *weekdayselectArray;
@end

@implementation KDSCycleSelectViewController
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [KDSUserManager sharedManager].weekSelectArray = _weekdayselectArray;
    NSLog(@"weekdayselectArray===%@",[KDSUserManager sharedManager].weekSelectArray);
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    _weekdayselectArray = [[NSMutableArray alloc] initWithObjects:@"1",@"1",@"1",@"1",@"1",@"1",@"1", nil];
}
- (NSMutableArray<NSIndexPath *> *)selectArr
{
    if (!_selectArr)
    {
        _selectArr = [NSMutableArray array];
    }
    return _selectArr;
}
- (NSMutableArray*)weekdayselectArray
{
    if (!_weekdayselectArray)
    {
        _weekdayselectArray = [NSMutableArray array];
    }
    return _weekdayselectArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = @"周重复";
    [self addlistView];
    [self addHeadView];
    _dataArray = @[@"每周日",@"每周一",@"每周二",@"每周三",@"每周四",@"每周五",@"每周六"];
}
-(void)addlistView{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 0, kScreenWidth-20, kScreenHeight) style:UITableViewStylePlain];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 60;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.layer.cornerRadius = 5;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"KDSWeekDaySelectTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSWeekDaySelectTableViewCell"];
    [self.view addSubview:_tableView];
}

-(void)addHeadView{
    _everydayView = [[KDSEverydayView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 80)];
    _everydayView.layer.cornerRadius = 5;
    _everydayView.everyDayImg.image = [UIImage imageNamed:@"deviceLanguageSelected"];
    __weak typeof(self) weakSelf = self;
    //当tag为1001时表示 全选
    weakSelf.everydayView.tag = 1001;
    [_everydayView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        weakSelf.everydayView.tag = 1001;
        weakSelf.everydayView.everyDayImg.image = [UIImage imageNamed:@"deviceLanguageSelected"];
        for (NSIndexPath *indexPath in weakSelf.selectArr) {
            KDSWeekDaySelectTableViewCell * cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
            cell.imageTagView.image = [UIImage imageNamed:@"deviceLanguageNormal"];
        }
        weakSelf.weekdayselectArray = [[NSMutableArray alloc] initWithObjects:@"1",@"1",@"1",@"1",@"1",@"1",@"1", nil];
        [weakSelf.selectArr removeAllObjects];
        [weakSelf.tableView reloadData];
    }];
    _tableView.tableHeaderView = _everydayView;
}
#pragma UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataArray.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSWeekDaySelectTableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    if([self.selectArr containsObject:indexPath]){
        [self.selectArr removeObject:indexPath];
        cell.imageTagView.image = [UIImage imageNamed:@"deviceLanguageNormal"];
    }else {
        [self.selectArr addObject:indexPath];
        cell.imageTagView.image = [UIImage imageNamed:@"deviceLanguageSelected"];
    }
    if (self.everydayView.tag == 1001) {
//        self.weekdayselectArray = [[NSMutableArray alloc] initWithObjects:@"1",@"1",@"1",@"1",@"1",@"1",@"1", nil];
        self.weekdayselectArray = [[NSMutableArray alloc] initWithObjects:@"0",@"0",@"0",@"0",@"0",@"0",@"0", nil];
    }
    if ([[self.weekdayselectArray objectAtIndex:indexPath.row] isEqualToString:@"1"]) {
        [self.weekdayselectArray replaceObjectAtIndex:indexPath.row withObject:@"0"];
    }else{
        [self.weekdayselectArray replaceObjectAtIndex:indexPath.row withObject:@"1"];
    }
    _everydayView.everyDayImg.image = [UIImage imageNamed:@"deviceLanguageNormal"];
    _everydayView.tag = 1002;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSWeekDaySelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSWeekDaySelectTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.weekDayLab.text = _dataArray[indexPath.row];
    if([self.selectArr containsObject:indexPath]){
        //设置选中图片
        cell.imageTagView.image = [UIImage imageNamed:@"deviceLanguageSelected"];
    }else {
        //设置未选中图片
        cell.imageTagView.image = [UIImage imageNamed:@"deviceLanguageNormal"];
    }
    return cell;
        
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
