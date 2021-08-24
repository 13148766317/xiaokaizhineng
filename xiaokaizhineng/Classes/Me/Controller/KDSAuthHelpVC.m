//
//  KDSAuthHelpVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/26.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAuthHelpVC.h"
#import "KDSDBManager.h"
#import "Masonry.h"
#import "MBProgressHUD+MJ.h"
#import "KDSAuthHelpCell.h"

@interface KDSAuthHelpVC () <UITableViewDataSource, UITableViewDelegate>

///验证异常记录。
@property (nonatomic, strong) NSArray<KDSAuthException *> *exceptions;
///显示无日志的图片视图。
@property (nonatomic, strong) UIImageView *noLogIV;

@end

@implementation KDSAuthHelpVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"helpLog");
    
    self.exceptions = [[KDSDBManager sharedManager] queryAuthExceptions:nil];
    if (self.exceptions.count == 0)
    {
        self.tableView.hidden = YES;
        self.noLogIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"meNoHelpLog"]];
        [self.view addSubview:self.noLogIV];
        [self.noLogIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.top.equalTo(self.view).offset(106);
            make.size.mas_equalTo(self.noLogIV.image.size);
        }];
    }
    else
    {
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(self.view).offset(10);
            make.right.equalTo(self.view).offset(-10);
            if (self.exceptions.count * 60.0 < kScreenHeight - kStatusBarHeight - kNavBarHeight - 20)
            {
                make.height.mas_equalTo(self.exceptions.count * 60);
            }
            else
            {
                make.bottom.equalTo(self.view).offset(-10);
            }
        }];
        self.tableView.layer.cornerRadius = 5;
        self.tableView.rowHeight = 60;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.exceptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSAuthHelpCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSAuthHelpCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    cell.exception = self.exceptions[indexPath.row];
    cell.hideSeparator = indexPath.row == self.exceptions.count - 1;
    
    return cell;
}

@end
