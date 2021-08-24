//
//  KDSDeviceTableViewCell.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/1/24.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSDeviceTableViewCell.h"

@interface KDSDeviceTableViewCell ()

///锁电量图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *powerIV;
///名称标签
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
///设备列表显示是T5\X5的锁的icon
@property (weak, nonatomic) IBOutlet UIImageView *deviceIconImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingDeviceConstraint;

@end

@implementation KDSDeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFrame:(CGRect)frame{
    frame.origin.x += 10;
    frame.origin.y += 10;
    frame.size.height -= 10;
    frame.size.width -= 20;
    self.layer.cornerRadius = 5;
    [super setFrame:frame];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setPower:(int)power
{
    _power = power;
    NSString *imgName = [KDSTool imageNameForPower:power];
    self.powerIV.image = [UIImage imageNamed:imgName];
}

- (void)setDevice:(MyDevice *)device
{
    _device = device;
    ///当蓝牙断链的时候，从服务器也读不到device.model的时候默认显示智能锁
    if (device.model.length > 0) {
        if ([device.model containsString:@"X5S"]) {
            self.deviceIconImageView.image = [UIImage imageNamed:@"deviceModelX5"];
        }else if ([device.model containsString:@"T5S"]){
            self.deviceIconImageView.image = [UIImage imageNamed:@"deviceModelT5S"];
        }else if ([device.model containsString:@"X5"]){
            self.deviceIconImageView.image = [UIImage imageNamed:@"deviceModelX5"];
        }else if ([device.model containsString:@"T5"]){
            self.deviceIconImageView.image = [UIImage imageNamed:@"deviceModelT5"];
        }else{
            self.deviceIconImageView.image = [UIImage imageNamed:@"deviceModelX5"];
        }
    }else{
        self.deviceIconImageView.image = [UIImage imageNamed:@"deviceModelX5"];
    }
    if (device.device_nickname) {
        self.nameLabel.text = device.device_nickname;
    }else{
        if ([device.model containsString:@"T5"]) {
            self.nameLabel.text = @"T5";
        }if ([device.model containsString:@"X5"]){
            self.nameLabel.text = @"X5";
        }if ([device.model containsString:@"T5S"]){
            self.nameLabel.text = @"T5S";
        }if ([device.model containsString:@"X5S"]){
            self.nameLabel.text = @"X5S";
        }
    }
}

@end
