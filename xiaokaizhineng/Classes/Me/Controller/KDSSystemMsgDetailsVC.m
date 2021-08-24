//
//  KDSSystemMsgDetailsVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/3/8.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSSystemMsgDetailsVC.h"
#import "KDSSysMsgDetailsCell.h"

@interface KDSSystemMsgDetailsVC () <UITableViewDataSource, UITableViewDelegate>

///行高。
@property (nonatomic, strong) NSArray<NSNumber *> *rowHeights;
///时间格式器，yyyy/MM/dd
@property (nonatomic, strong) NSDateFormatter *dateFmt;

@end

@implementation KDSSystemMsgDetailsVC

- (void)setMessages:(NSArray<KDSSysMessage *> *)messages
{
    _messages = messages;
    NSMutableArray *heights = [NSMutableArray arrayWithCapacity:messages.count];
    for (KDSSysMessage *message in messages)
    {
        CGFloat tHeight = ceil([message.title boundingRectWithSize:CGSizeMake(kScreenWidth - 50, kScreenHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15]} context:nil].size.height);
        CGFloat cHeight = ceil([message.content boundingRectWithSize:CGSizeMake(kScreenWidth - 50, kScreenHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15]} context:nil].size.height);
        [heights addObject:@(51 + 20 + tHeight + 14 + cHeight + 19)];
    }
    self.rowHeights = heights;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dateFmt = [[NSDateFormatter alloc] init];
    self.dateFmt.dateFormat = @"yyyy/MM/dd HH:mm";
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view).offset(10);
        make.bottom.right.equalTo(self.view).offset(-10);
    }];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = self.view.backgroundColor;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.rowHeights[indexPath.row].doubleValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSSysMsgDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSSysMsgDetailsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    KDSSysMessage *message = self.messages[indexPath.row];
    cell.title = message.title;
    cell.content = message.content;
    cell.date = [self.dateFmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:message.createTime]];
    
    return cell;
}

@end
