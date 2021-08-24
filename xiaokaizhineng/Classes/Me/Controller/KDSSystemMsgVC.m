//
//  KDSSystemMsgVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSSystemMsgVC.h"
#import "KDSHttpManager+User.h"
#import "KDSDBManager.h"
#import "MJRefresh.h"
#import "MBProgressHUD+MJ.h"
#import "KDSSysMsgCell.h"
#import "KDSSystemMsgDetailsVC.h"

@interface KDSSystemMsgVC () <UITableViewDataSource, UITableViewDelegate>

///暂无消息视图。
@property (nonatomic, strong) UIView *noMsgView;
///圆角视图。
@property (nonatomic, strong) UIView *cornerView;
///数据源数组。
@property (nonatomic, strong) NSMutableArray<KDSSysMessage *> *messages;
///左滑删除事件。
@property (nonatomic, strong) UITableViewRowAction *deleteAction;
///时间格式器，yyyy/MM/dd
@property (nonatomic, strong) NSDateFormatter *dateFmt;

@end

@implementation KDSSystemMsgVC

#pragma mark - 懒加载
- (UIView *)noMsgView
{
    if (!_noMsgView)
    {
        UIImage *img = [UIImage imageNamed:@"meNoSystemMsg"];
        _noMsgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth - 20, 106 + img.size.height)];
        UIImageView *iv = [[UIImageView alloc] initWithImage:img];
        iv.frame = (CGRect){(kScreenWidth - 20 - img.size.width) / 2, 106, img.size};
        [_noMsgView addSubview:iv];
    }
    return _noMsgView;
}

- (UITableViewRowAction *)deleteAction
{
    if (!_deleteAction)
    {
        __weak typeof(self) weakSelf = self;
        _deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:Localized(@"delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            KDSSysMessage *message = weakSelf.messages[indexPath.row];
            [weakSelf.messages removeObject:message];
            [weakSelf.tableView beginUpdates];
            [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
            [weakSelf.tableView endUpdates];
            [weakSelf scrollViewDidScroll:weakSelf.tableView];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                message.deleted = YES;
                [[KDSDBManager sharedManager] insertFAQOrMessage:@[message]];
                [weakSelf deleteSystemMessage:message];
            });
        }];
    }
    return _deleteAction;
}

#pragma mark - 生命周期方法
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"message");
    self.dateFmt = [[NSDateFormatter alloc] init];
    self.dateFmt.dateFormat = @"yyyy/MM/dd";
    self.messages = [NSMutableArray array];
    NSArray<KDSSysMessage *> *dbArr = [[KDSDBManager sharedManager] queryFAQOrMessage:2];
    if (!dbArr)
    {
        self.tableView.tableHeaderView = self.noMsgView;
    }
    else
    {
        [self.messages addObjectsFromArray:dbArr];
    }
    
    CGFloat maxHeight = kScreenHeight - kStatusBarHeight - kNavBarHeight - 20;
    CGFloat height = dbArr.count*70 > maxHeight ? maxHeight : dbArr.count*70;
    self.cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, kScreenWidth - 20, height)];
    self.cornerView.layer.cornerRadius = 5;
    self.cornerView.backgroundColor = UIColor.whiteColor;
    [self.view insertSubview:self.cornerView atIndex:0];
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(10);
        make.bottom.right.equalTo(self.view).offset(-10);
    }];
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getSystemMessage:1];
    }];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 70;
    
    [self getSystemMessage:1];
}

#pragma mark - 网络请求方法
///获取第几页的消息，从1起。
- (void)getSystemMessage:(int)page
{
    [[KDSHttpManager sharedManager] getSystemMessageWithUid:[KDSUserManager sharedManager].user.uid page:page success:^(NSArray<KDSSysMessage *> * _Nonnull messages) {
        
        NSArray<KDSSysMessage *> *dbArr = [[KDSDBManager sharedManager] queryFAQOrMessage:2];
        NSArray *deletedArr = [[KDSDBManager sharedManager] queryFAQOrMessage:4];
        NSMutableArray<KDSSysMessage *> *mergeArr = [NSMutableArray arrayWithArray:dbArr ?: @[]];
        //删除状态已本地记录为准。
        for (KDSSysMessage *message in messages)
        {
            if (![deletedArr containsObject:message]) [mergeArr addObject:message];
        }
        [self.messages removeAllObjects];
        [self.messages addObjectsFromArray:mergeArr];
        self.tableView.tableHeaderView = mergeArr.count ? nil : self.noMsgView;
        [self.tableView reloadData];
        CGFloat maxHeight = kScreenHeight - kStatusBarHeight - kNavBarHeight - 20;
        CGFloat height = dbArr.count*70 > maxHeight ? maxHeight : dbArr.count*70;
        self.cornerView.frame = CGRectMake(10, 10, kScreenWidth - 20, height);
        self.tableView.mj_header.state = MJRefreshStateIdle;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            for (KDSSysMessage *msg in messages)
            {
                if ([deletedArr containsObject:msg]) msg.deleted = YES;
            }
            [[KDSDBManager sharedManager] insertFAQOrMessage:messages];
            [self deleteSystemMessage:nil];
        });
        
    } error:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        NSArray<KDSSysMessage *> *messages = [[KDSDBManager sharedManager] queryFAQOrMessage:2];
        if (!messages.count)
        {
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.localizedDescription]];
        }
    } failure:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        NSArray<KDSSysMessage *> *messages = [[KDSDBManager sharedManager] queryFAQOrMessage:2];
        if (!messages.count)
        {
            [MBProgressHUD showError:error.localizedDescription];
        }
    }];
}

///删除本地的系统消息。该方法内会查询本地有没有已标记删除的消息，如果有会请求服务器将其删除，请在子线程执行。
- (void)deleteSystemMessage:(KDSSysMessage * __nullable )message
{
    NSArray *deleted = [[KDSDBManager sharedManager] queryFAQOrMessage:4];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:deleted ?: @[]];
    !message ?: [arr addObject:message];
    for (KDSSysMessage *msg in arr)
    {
        [[KDSHttpManager sharedManager] deleteSystemMessage:msg withUid:[KDSUserManager sharedManager].user.uid success:^{
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[KDSDBManager sharedManager] deleteFAQOrMessage:msg type:2];
            });
            
        } error:nil failure:nil];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat maxHeight = kScreenHeight - kStatusBarHeight - kNavBarHeight - 20;
    CGFloat rowHeight = self.tableView.rowHeight;
    CGFloat height = self.messages.count * rowHeight;
    if (offsetY < 0)
    {
        //不能超过上限
        CGFloat originY = 10 - offsetY;
        height = height + originY > maxHeight ? maxHeight + 10 - originY : height;
        height = height < 0 ? 0 : height;
        self.cornerView.frame = CGRectMake(10, originY, kScreenWidth - 20, height);
    }
    else
    {
        //不能超过上下限
        height -= offsetY;
        height = height > maxHeight ? maxHeight : height;
        height = height < 0 ? 0 : height;
        self.cornerView.frame = CGRectMake(10, 10, kScreenWidth - 20, height);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidScroll:scrollView];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @[self.deleteAction];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSSysMsgCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSSysMsgCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    KDSSysMessage *message = self.messages[indexPath.row];
    cell.title = message.title;
    cell.date = [self.dateFmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:message.createTime]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KDSSystemMsgDetailsVC *vc = [[KDSSystemMsgDetailsVC alloc] init];
    vc.messages = self.messages;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
