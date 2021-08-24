//
//  KDSDFUViewController.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/8/8.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"
#import "JGProgressView.h"
NS_ASSUME_NONNULL_BEGIN

@interface KDSDFUViewController : KDSAutoConnectViewController
@property (weak, nonatomic) IBOutlet UILabel *Psoc6DFUCurrentStatus;
///正在升级请勿操作.....的提示图标 和 Psoc6DFUCurrentStatus结合使用显示/隐藏是一致的
@property (weak, nonatomic) IBOutlet UIImageView *Psoc6DFUCurrentStatusImagView;

@property (weak, nonatomic) IBOutlet UILabel *Psoc6DFUTotalBlock;
@property (weak, nonatomic) IBOutlet UILabel *Psoc6DFUCurrentBlock;
///当前连接的蓝牙设备
@property (nonatomic, strong) CBPeripheral *peripheral;
///用来展示自定义进度条的父视图
//@property (weak, nonatomic) IBOutlet UIView *progressView;
////展示：下载、进入升级状态、正在升级、完成的进度条的父视图
@property (weak, nonatomic) IBOutlet UIView *topProgressView;
///开始升级按钮
@property (weak, nonatomic) IBOutlet UIButton *startUpgradingBtn;
///显示下载进度的label
@property (weak, nonatomic) IBOutlet UILabel *progressViewLabel;
///显示下载进度的背景图
@property (weak, nonatomic) IBOutlet UIImageView *progressViewImg;
///下载、进入升级状态之间
@property (weak, nonatomic) IBOutlet UIImageView *line1Img;
///进入升级状态、正在升级之间
@property (weak, nonatomic) IBOutlet UIImageView *line2Img;
///正在升级、完成之间
@property (weak, nonatomic) IBOutlet UIImageView *line3Img;
///下载状态图
@property (weak, nonatomic) IBOutlet UIImageView *icon1Img;
///进入升级状态状态图
@property (weak, nonatomic) IBOutlet UIImageView *icon2Img;
///正在升级状态图
@property (weak, nonatomic) IBOutlet UIImageView *icon3Img;
///完成状态图
@property (weak, nonatomic) IBOutlet UIImageView *icon4Img;
////下载的进度----根据下载内容和总内容的比-----更改图片的width
//@property (weak, nonatomic) IBOutlet UIImageView *dynamicImageView;
//@property (nonatomic, strong) UIView *progressView;
@property (weak, nonatomic) IBOutlet UIView *progressSubview;

/// 蓝牙NSUUID
@property (nonatomic, copy) NSUUID *peripheralWithIdentifier;
/// 进度（值范围0.0~1.0，默认0.0）
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic,strong)MyDevice *dev;
@property (nonatomic, strong) KDSBluetoothTool *bluetoothTool;
///固件下载地址
@property (strong, nonatomic)  NSString *url;
///当前是bootload模式
@property (assign, nonatomic)  BOOL isBootLoadModel;
///倒计时秒数。初始化时为5
@property (nonatomic, assign) NSInteger countdown;
@property (weak, nonatomic) IBOutlet JGProgressView *currentProgressView;

@end

NS_ASSUME_NONNULL_END
