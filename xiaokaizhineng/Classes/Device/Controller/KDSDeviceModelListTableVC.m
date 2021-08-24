//
//  KDSDeviceModelListTableVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/12.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSDeviceModelListTableVC.h"
#import "KDSDeviceModelCell.h"
#import "KDSBleBindVC.h"

@interface KDSDeviceModelListTableVC () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation KDSDeviceModelListTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.backgroundColor = KDSRGBColor(0xee, 0xee, 0xee);
    self.tableView.rowHeight = 132;
    self.tableView.sectionHeaderHeight = 10;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.navigationTitleLabel.text = Localized(@"addDevice");
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSDeviceModelCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSDeviceModelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    switch (indexPath.section) {
        case 0:
            cell.model = KDSDeviceModelT5;
            break;
        case 1:
            cell.model = KDSDeviceModelX5;
            break;
        case 2:
            cell.model = KDSDeviceModelT5S;
            break;
        case 3:
            cell.model = KDSDeviceModelX5S;
            break;
        default:
            break;
    }
//    cell.model = indexPath.section ? KDSDeviceModelX5 : KDSDeviceModelT5;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KDSDeviceModelCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    KDSBleBindVC *vc = [KDSBleBindVC new];
    vc.model = cell.model;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
