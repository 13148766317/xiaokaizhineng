//
//  KDSAddKeyVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/3/4.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAddKeyVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "UIView+Extension.h"

@interface KDSAddKeyVC ()

///提示标签。
@property (nonatomic, strong) UILabel *tipsLabel;
///添加卡片、指纹时的编号。
@property (nonatomic, assign) int num;
//蓝牙未连接时用到的属性
///搜索蓝牙时转圈的动画视图。
@property (nonatomic, strong) UIImageView *animationIV;
///转圈动画定时器。
@property (nonatomic, strong) NSTimer *animationTimer;
///连接门锁蓝牙中状态提示标签。
@property (nonatomic, strong) UILabel *connectingLabel;

//正在添加、添加失败时时用到的属性。
///T5、X5模型图片视图。
@property (nonatomic, strong) UIImageView *modelIV;
///步骤标签。
@property (nonatomic, strong) UILabel *stepLabel;
///步骤按钮。
@property (nonatomic, strong) UIButton *stepBtn;
@property (nonatomic, strong) UIView * failSupView;

//添加成功时使用到的属性。
///卡片/指纹图片。
@property (nonatomic, strong) UIImageView *figureIV;
///输入昵称的文本框。
@property (nonatomic, strong) UITextField *textField;
///8个预设昵称的按钮数组。
@property (nonatomic, strong) NSArray<UIButton *> *buttons;
///保存按钮。
@property (nonatomic, strong) UIButton *saveBtn;
///添加指纹定时器。
@property (nonatomic, strong) NSTimer *addKeyTimer;
@end

@implementation KDSAddKeyVC

#pragma mark - getter setter
- (UIImageView *)animationIV
{
    if (!_animationIV)
    {
        _animationIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"deviceSearchingBle"]];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAnimationIVToSearchBle:)];
        [_animationIV addGestureRecognizer:tap];
        [self.view addSubview:_animationIV];
    }
    return _animationIV;
}

- (NSTimer *)animationTimer
{
    if (!_animationTimer)
    {
        _animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30 target:self selector:@selector(animationTimerAction:) userInfo:nil repeats:YES];
    }
    return _animationTimer;
}

- (UILabel *)connectingLabel
{
    if (!_connectingLabel)
    {
        _connectingLabel = [[UILabel alloc] init];
        _connectingLabel.text = Localized(@"connectingLock");
        _connectingLabel.textColor = KDSRGBColor(0x14, 0x14, 0x14);
        _connectingLabel.font = [UIFont systemFontOfSize:18];
        _connectingLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_connectingLabel];
    }
    return _connectingLabel;
}

- (UILabel *)tipsLabel
{
    if (!_tipsLabel)
    {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.numberOfLines = 0;
        _tipsLabel.text = Localized(@"openBleAndStandByDoorLock");
        _tipsLabel.textColor = KDSRGBColor(0x14, 0x14, 0x14);
        _tipsLabel.font = [UIFont systemFontOfSize:18];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_tipsLabel];
    }
    return _tipsLabel;
}

- (UIImageView *)modelIV
{
    if (!_modelIV)
    {
        _modelIV = [[UIImageView alloc] init];
        [self.view addSubview:_modelIV];
    }
    return _modelIV;
}

#pragma mark - 初始化、UI相关方法。
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.type = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(self.type==0 ? @"addCard" : @"addFingerprint");
    if (!self.lock.bleTool.connectedPeripheral)
    {
        [self setupConnectingUI];
    }
    else
    {
        [self setupSettingKeyUI];
    }
    __weak typeof(self) weakSelf = self;
    self.authenticateSuccess = ^{
        [weakSelf setupSettingKeyUI];
    };
    self.view.backgroundColor = UIColor.whiteColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockDidReportOperationResult:) name:KDSLockDidReportNotification object:nil];
      self.addKeyTimer = [NSTimer scheduledTimerWithTimeInterval:80.0 target:self selector:@selector(animationTimerActionStopAddKeyIfFail:) userInfo:nil repeats:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.lock.bleTool.connectedPeripheral && _animationIV)
    {
        [self.animationTimer fire];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_animationTimer.isValid)
    {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

///设置未连接蓝牙时的界面。
- (void)setupConnectingUI
{
    [self.animationIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-4 - self.animationIV.image.size.height / 2);
        make.size.mas_equalTo(self.animationIV.image.size);
    }];
    [self.connectingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationIV.mas_bottom).offset(21);
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(ceil([self.connectingLabel.text sizeWithAttributes:@{NSFontAttributeName : self.connectingLabel.font}].height));
    }];
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.connectingLabel.mas_bottom).offset(20);
        make.leftMargin.rightMargin.equalTo(self.connectingLabel);
        make.height.mas_lessThanOrEqualTo(40);
    }];
    [self.animationTimer fire];
}

///设置正在添加门卡或指纹时的界面。
- (void)setupSettingKeyUI
{
    [_animationTimer invalidate];
    _animationTimer = nil;
    [_animationIV removeFromSuperview];
    _animationIV = nil;
    [_connectingLabel removeFromSuperview];
    _connectingLabel = nil;

    UIView *topGrayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 10)];
    topGrayView.backgroundColor = KDSRGBColor(249, 249, 249);
    [self.view addSubview:topGrayView];
    
    NSString *name = [self.lock.device.model containsString:@"X5"] ? (self.type==0 ? @"deviceSecurityModeX5" :@"X5-添加指纹3") : (self.type==0 ? @"X5-添加指纹成功" : @"deviceSecurityModeT5");
    UIImage *img = [UIImage imageNamed:name];
    self.modelIV.image = img;
    if (self.modelIV.height ==0) {
        [self.modelIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset((kScreenHeight - kStatusBarHeight - kNavBarHeight - img.size.height - 42) / 3);
            make.centerX.equalTo(self.view);
            make.size.mas_equalTo(img.size);
        }];
    }
    self.tipsLabel.text = Localized(self.type==0 ? @"addCardTips" : @"addFingerprintTips");
    if (_tipsLabel)
    {
        [self.tipsLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.modelIV.mas_bottom).offset(30);
            make.left.equalTo(self.view).offset(10);
            make.right.equalTo(self.view).offset(-10);
            make.height.mas_lessThanOrEqualTo(60);
        }];
    }else{
        [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.modelIV.mas_bottom).offset(30);
            make.left.equalTo(self.view).offset(10);
            make.right.equalTo(self.view).offset(-10);
            make.height.mas_lessThanOrEqualTo(60);
        }];
    }
    if (self.stepLabel) {
        
        [self.tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.stepLabel.mas_bottom).offset(20);
            make.left.equalTo(self.failSupView).offset(10);
            make.right.equalTo(self.failSupView).offset(-10);
            make.height.mas_lessThanOrEqualTo(60);
        }];
        CGSize size = self.modelIV.image.size;
        [self.modelIV mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.failSupView);
            make.centerY.equalTo(self.failSupView);
            make.size.mas_equalTo(kScreenHeight<667 ? (CGSize){size.width * 0.8, size.height * 0.8} : size);
        }];
        [self.stepBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.failSupView);
            make.bottom.equalTo(self.failSupView).offset(kScreenHeight<667 ? -20 : -43);
            make.size.mas_equalTo(CGSizeMake(300, 60));
        }];
        
    }
    
    self.tipsLabel.font = [UIFont systemFontOfSize:12];
    __weak typeof(self) weakSelf = self;
    KDSBleKeyType type = self.type==0 ? KDSBleKeyTypeRFID : KDSBleKeyTypeFingerprint;
    [self getAllKeys:type times:0 completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
        if (error == KDSBleErrorSuccess)
        {
            int num = (int)users.count;//序号
            for (int i = 0; i < users.count; ++i)
            {
                if (users[i].userId != i)
                {
                    num = i;
                    break;
                }
            }
            weakSelf.num = num;
            [weakSelf setKey:type userId:num];
        }
        else
        {
            [weakSelf setupFailedUI];
            [MBProgressHUD showError:[@"error" stringByAppendingFormat:@": %ld", (long)error]];
        }
    }];
    
    NSLog(@"self.modelIV2--- %@ \n self.tipsLabel----%@",self.modelIV,self.tipsLabel);
}

///设置添加成功时的界面。
- (void)setupSuccessUI
{
    [self.modelIV removeFromSuperview];
    self.modelIV = nil;
    [_stepBtn removeFromSuperview];
    [self.failSupView removeFromSuperview];
    
    UIImage *img = [UIImage imageNamed:self.type==0 ? @"卡片-1" : @"icon-添加指纹成功"];
    self.figureIV = [[UIImageView alloc] initWithImage:img];
    [self.view addSubview:self.figureIV];
    [self.figureIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kScreenHeight<667 ? 25 : 50);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(img.size);
    }];
    self.tipsLabel.text = [NSString stringWithFormat:Localized(self.type==0 ? @"cardAddSuccessTips": @"fingerpringAddSuccessTips"), self.num + 1];
    self.tipsLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:self.tipsLabel];
    [self.tipsLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.figureIV.mas_bottom).offset(20);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(ceil([self.tipsLabel.text sizeWithAttributes:@{NSFontAttributeName : self.tipsLabel.font}].height));
    }];
    
    UIView *cornerView = [UIView new];
    cornerView.backgroundColor = UIColor.whiteColor;
    cornerView.layer.cornerRadius = 25;
    cornerView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    cornerView.layer.shadowOffset = CGSizeMake(3, 3);
    cornerView.layer.shadowOpacity = 1.0;
    [self.view addSubview:cornerView];
    [cornerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(kScreenHeight<667 ? 25 : 45);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(300, 50));
    }];
    UIImage *leftImg = [UIImage imageNamed:@"名称"];
    UIImageView *leftIV = [[UIImageView alloc] initWithImage:leftImg];
    [cornerView addSubview:leftIV];
    [leftIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cornerView).offset(23);
        make.top.equalTo(cornerView).offset((50 - leftImg.size.height) / 2.0);
        make.size.mas_equalTo(leftImg.size);
    }];
    self.textField = [[UITextField alloc] init];
    self.textField.placeholder = Localized(@"inputOrSelectAName");
    self.textField.font = [UIFont systemFontOfSize:14];
    [self.textField addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [cornerView addSubview:self.textField];
    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(cornerView);
        make.left.equalTo(leftIV.mas_right).offset(20);
        make.right.equalTo(cornerView).offset(-20);
    }];
    NSArray *names = @[Localized(@"nanny"), Localized(@"grandfather"), Localized(@"grandmother"), Localized(@"sister"), Localized(@"me"), Localized(@"grandma"), Localized(@"grandpa"), Localized(@"mother")];
    NSMutableArray<NSNumber *> *lengths = [NSMutableArray arrayWithCapacity:8];//文字宽度
    NSMutableArray<UIButton *> *btns = [NSMutableArray arrayWithCapacity:8];
    UIFont *font = [UIFont systemFontOfSize:13];
    for (int i = 0; i < 8; ++i)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = i==0 ? KDSRGBColor(0xf8, 0xf8, 0xf8) : UIColor.whiteColor;
        btn.layer.borderColor = KDSRGBColor(0xee, 0xee, 0xee).CGColor;
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 17;
        [btn setTitle:names[i] forState:UIControlStateNormal];
        [btn setTitleColor:KDSRGBColor(0x8f, 0x92, 0xa6) forState:UIControlStateNormal];
        [btn setTitleColor:KDSRGBColor(0x44, 0x48, 0x6b) forState:UIControlStateSelected];
        btn.titleLabel.font = font;
        [btn addTarget:self action:@selector(selectBtn:) forControlEvents:UIControlEventTouchUpInside];
        [lengths addObject:@([names[i] sizeWithAttributes:@{NSFontAttributeName : font}].width)];
        [self.view addSubview:btn];
        [btns addObject:btn];
    }
    btns.firstObject.selected = YES;
    self.textField.text = names.firstObject;
    self.buttons = btns.copy;
    CGFloat topOffset = kScreenHeight < 667 ? 10 : 16;
    //正常的按钮宽60高34，间距13~14。
    if (lengths[0].intValue > 40 || lengths[1].intValue > 40 || lengths[2].intValue > 40 || lengths[3].intValue > 40)
    {//分2行
        [btns[0] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cornerView.mas_bottom).offset(topOffset);
            make.left.equalTo(cornerView).offset(10);
            make.size.mas_equalTo((CGSize){(300 - 14 - 20) / 2.0, 34});
        }];
        [btns[1] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cornerView.mas_bottom).offset(topOffset);
            make.right.equalTo(cornerView).offset(-10);
            make.size.equalTo(btns[0]);
        }];
        [btns[2] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[0].mas_bottom).offset(topOffset);
            make.left.equalTo(cornerView).offset(10);
            make.size.equalTo(btns[0]);
        }];
        [btns[3] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[1].mas_bottom).offset(topOffset);
            make.right.equalTo(cornerView).offset(-10);
            make.size.equalTo(btns[0]);
        }];
    }
    else
    {
        [btns[0] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cornerView.mas_bottom).offset(topOffset);
            make.left.equalTo(cornerView).offset(10);
            make.size.mas_equalTo((CGSize){60, 34});
        }];
        [btns[1] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cornerView.mas_bottom).offset(topOffset);
            make.left.equalTo(btns[0].mas_right).offset(13);
            make.size.equalTo(btns[0]);
        }];
        [btns[2] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cornerView.mas_bottom).offset(topOffset);
            make.left.equalTo(btns[1].mas_right).offset(14);
            make.size.equalTo(btns[0]);
        }];
        [btns[3] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cornerView.mas_bottom).offset(topOffset);
            make.right.equalTo(cornerView).offset(-10);
            make.size.equalTo(btns[0]);
        }];
    }
    if (lengths[4].intValue > 40 || lengths[5].intValue > 40 || lengths[6].intValue > 40 || lengths[7].intValue > 40)
    {//分2行
        [btns[4] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[2].mas_bottom).offset(topOffset);
            make.left.equalTo(cornerView).offset(10);
            make.size.mas_equalTo((CGSize){(300 - 14 - 20) / 2.0, 34});
        }];
        [btns[5] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[3].mas_bottom).offset(topOffset);
            make.right.equalTo(cornerView).offset(-10);
            make.size.equalTo(btns[0]);
        }];
        [btns[6] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[4].mas_bottom).offset(topOffset);
            make.left.equalTo(cornerView).offset(10);
            make.size.equalTo(btns[0]);
        }];
        [btns[7] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[5].mas_bottom).offset(topOffset);
            make.right.equalTo(cornerView).offset(-10);
            make.size.equalTo(btns[0]);
        }];
    }
    else
    {
        [btns[4] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[0].mas_bottom).offset(topOffset);
            make.left.equalTo(cornerView).offset(10);
            make.size.mas_equalTo((CGSize){60, 34});
        }];
        [btns[5] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[1].mas_bottom).offset(topOffset);
            make.left.equalTo(btns[4].mas_right).offset(13);
            make.size.equalTo(btns[0]);
        }];
        [btns[6] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[2].mas_bottom).offset(topOffset);
            make.left.equalTo(btns[5].mas_right).offset(14);
            make.size.equalTo(btns[0]);
        }];
        [btns[7] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btns[3].mas_bottom).offset(topOffset);
            make.right.equalTo(cornerView).offset(-10);
            make.size.equalTo(btns[0]);
        }];
    }
    self.saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.saveBtn.layer.shadowColor = [UIColor colorWithRed:0x2d/255.0 green:0xd9/255.0 blue:0xba/255.0 alpha:0.3].CGColor;
    self.saveBtn.layer.shadowOffset = CGSizeMake(3, 3);
    self.saveBtn.layer.shadowOpacity = 1;
    self.saveBtn.layer.cornerRadius = 30;
    [self.saveBtn setTitle:Localized(@"save") forState:UIControlStateNormal];
    [self.saveBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.saveBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.saveBtn addTarget:self action:@selector(saveBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveBtn];
    [self.saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(kScreenHeight<667 ? -30 : -79);
        make.size.mas_equalTo(CGSizeMake(300, 60));
    }];
}

///设置添加失败时的界面。
- (void)setupFailedUI
{
    [_figureIV removeFromSuperview];
    [_textField.superview removeFromSuperview];
    [_modelIV removeFromSuperview];
    _modelIV = nil;
    for (UIButton *btn in self.buttons)
    {
        [btn removeFromSuperview];
    }
    [_saveBtn removeFromSuperview];
    
    self.failSupView = [UIView new];
    self.failSupView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.failSupView];
    [self.failSupView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.mas_equalTo(10);
    }];
    
    self.stepLabel = [[UILabel alloc] init];
    self.stepLabel.text = Localized(@"bleBindStep1");
    self.stepLabel.font = [UIFont systemFontOfSize:18];
    self.stepLabel.textColor = KDSRGBColor(0x14, 0x14, 0x14);
    self.stepLabel.textAlignment = NSTextAlignmentCenter;
    [self.failSupView addSubview:self.stepLabel];
    [self.stepLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kScreenHeight<667 ? 20 : 38);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(ceil([self.stepLabel.text sizeWithAttributes:@{NSFontAttributeName : self.stepLabel.font}].height));
    }];
    
    self.stepBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stepBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.stepBtn.layer.shadowColor = [UIColor colorWithRed:0x2d/255.0 green:0xd9/255.0 blue:0xba/255.0 alpha:0.3].CGColor;
    self.stepBtn.layer.shadowOffset = CGSizeMake(3, 3);
    self.stepBtn.layer.shadowOpacity = 1;
    self.stepBtn.layer.cornerRadius = 30;
    [self.stepBtn setTitle:Localized(@"nextStep") forState:UIControlStateNormal];
    [self.stepBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.stepBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.stepBtn addTarget:self action:@selector(stepBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.failSupView addSubview:self.stepBtn];
    [self.stepBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.failSupView);
        make.bottom.equalTo(self.failSupView).offset(kScreenHeight<667 ? -20 : -43);
        make.size.mas_equalTo(CGSizeMake(300, 60));
    }];
    
    self.modelIV.image = [UIImage imageNamed:[self.lock.device.model containsString:@"X5"] ? @"X5-添加门卡1" : @"T5-添加指纹1"];
    CGSize size = self.modelIV.image.size;
    if (self.modelIV) {
        [self.modelIV mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.stepBtn.mas_top).offset(kScreenHeight<667 ? -20 : -48);
            make.size.mas_equalTo(kScreenHeight<667 ? (CGSize){size.width * 0.8, size.height * 0.8} : size);
        }];
    }else{
        [self.modelIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.stepBtn.mas_top).offset(kScreenHeight<667 ? -20 : -48);
            make.size.mas_equalTo(kScreenHeight<667 ? (CGSize){size.width * 0.8, size.height * 0.8} : size);
        }];
    }
    
    [self.failSupView addSubview:self.tipsLabel];
    [self.tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stepLabel.mas_bottom);
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.bottom.equalTo(self.modelIV.mas_top).offset(-10);
    }];
    self.tipsLabel.font = [UIFont systemFontOfSize:12];
    self.tipsLabel.numberOfLines = 0;
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    self.tipsLabel.textColor = KDSRGBColor(0x14, 0x14, 0x14);
    self.tipsLabel.text = Localized(self.type==0 ? @"addCardFailedTips1" : @"addFingerprintFailedTips1");
}

#pragma mark - 控件等事件方法。
///定时器执行改变转置矩阵做动画，蓝牙未连接时使用。
- (void)animationTimerAction:(NSTimer *)timer
{
    self.animationIV.transform = CGAffineTransformRotate(self.animationIV.transform, M_PI / 30);
}

///点击动画视图重新搜索并连接蓝牙，蓝牙未连接时使用。
- (void)tapAnimationIVToSearchBle:(UITapGestureRecognizer *)tap
{
    self.animationIV.userInteractionEnabled = NO;
    _connectingLabel.text = Localized(@"connectingLock");
    [self.lock.bleTool beginScanForPeripherals];
    self.animationTimer.fireDate = NSDate.date;
}

///添加成功后输入名称的文本框文字发送改变，限制名称长度16.添加成功时使用。
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}

///选择名称时更改8个按钮的背景色，添加成功时使用。
- (void)selectBtn:(UIButton *)sender
{
    for (UIButton *btn in self.buttons)
    {
        btn.backgroundColor = UIColor.whiteColor;
        btn.selected = NO;
    }
    sender.backgroundColor = KDSRGBColor(0xf8, 0xf8, 0xf8);
    sender.selected = YES;
    self.textField.text = sender.currentTitle;
}

///点击保存按钮保存卡片、指纹昵称，添加成功时使用。
- (void)saveBtnAction:(UIButton *)sender
{
    NSString *name = self.textField.text;
    if (!name.length)
    {
        for (UIButton *btn in self.buttons)
        {
            if (btn.selected)
            {
                name = btn.currentTitle;
                break;
            }
        }
    }
    KDSPwdListModel *m = [KDSPwdListModel new];
    m.num = [NSString stringWithFormat:@"%02d", self.num];
    m.nickName = name;
    m.pwdType = self.type==0 ? KDSServerKeyTpyeCard : KDSServerKeyTpyeFingerprint;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    [[KDSHttpManager sharedManager] addBlePwds:@[m] withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^{
        [hud hide:YES];
        [MBProgressHUD showSuccess:Localized(@"Addasuccess")];
        [self.navigationController popViewControllerAnimated:YES];
        !self.keyAddSuccessBlock ?: self.keyAddSuccessBlock(m);
    } error:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@: %ld", Localized(@"saveFailed"), (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@， %@", Localized(@"saveFailed"), error.localizedDescription]];
    }];
}

///点击下一步按提示用户在锁上添加卡片、指纹，添加失败时使用。
- (void)stepBtnAction:(UIButton *)sender
{
    sender.tag += 1;
    if (sender.tag == 1)
    {
        self.stepLabel.text = Localized(@"bleBindStep2");
        self.tipsLabel.text = Localized(self.type==0 ? @"addCardFailedTips2" : @"addFingerprintFailedTips2");
        self.modelIV.image = [UIImage imageNamed:[self.lock.device.model containsString:@"X5"] ? @"X5-添加门卡2" : @"T5-添加指纹2"];
    }
    else if (sender.tag == 2)
    {
        self.stepLabel.text = Localized(@"bleBindStep3");
        [sender setTitle:Localized(@"done") forState:UIControlStateNormal];
        self.tipsLabel.text = Localized(self.type==0 ? @"addCardFailedTips3" : @"addFingerprintFailedTips3");
        self.modelIV.image = [UIImage imageNamed:[self.lock.device.model containsString:@"X5"] ? (self.type==0 ? @"X5-添加门卡3" : @"X5-添加指纹3") : (self.type==0 ? @"T5-添加门锁3" : @"T5-添加指纹3")];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 通知。
///锁上报操作结果，从数据中提取添加操作是否成功。
- (void)lockDidReportOperationResult:(NSNotification *)noti
{
    CBPeripheral *peripheral = noti.userInfo[@"peripheral"];
    NSData *data = noti.userInfo[@"data"];
    const Byte * bytes = data.bytes;
    if (peripheral == self.lock.bleTool.connectedPeripheral && data.length == 20 && bytes[4] == 2)
    {
        if ((bytes[5] == 3 && bytes[6] == 5 && self.type == 0) || (bytes[5] == 4 && bytes[6] == 7 && self.type == 1))
        {
            [self setupSuccessUI];
        }
    }
}
-(void)animationTimerActionStopAddKeyIfFail:(NSTimer *)ti{
    
    [self setupFailedUI];
}


#pragma mark - 蓝牙功能相关方法。
///获取已设置的所有卡片、指纹，调用时times传0，最多3次，3次都失败就算失败，completion是获取操作完毕后的回调，成功时users才有意义。
- (void)getAllKeys:(KDSBleKeyType)type times:(int)times completion:(void(^)(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users))completion
{
    KDSBluetoothTool *tool = self.lock.bleTool;
    __weak typeof(self) weakSelf = self;
    [tool getAllUsersWithKeyType:type completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
        if (error == KDSBleErrorSuccess)
        {
            !completion ?: completion(error, users);
        }
        else if (times < 2)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf getAllKeys:type times:times + 1 completion:completion];
            });
        }
        else
        {
            !completion ?: completion(error, users);
        }
    }];
}

///设置卡片、指纹，userId是卡片或指纹的编号。设置成功后，如果用户不点击保存直接退出控制器，不保存资料到本地和服务器。
- (void)setKey:(KDSBleKeyType)type userId:(int)userId
{
    KDSBluetoothTool *tool = self.lock.bleTool;
    __weak typeof(self) weakSelf = self;
    [tool manageKeyWithPwd:@"" userId:@(userId).stringValue action:KDSBleKeyManageActionSet keyType:type completion:^(KDSBleError error) {
        if (error != KDSBleErrorSuccess)
        {
            [weakSelf setupFailedUI];
        }
    }];
}

#pragma mark - KDSBluetoothToolDelegate
- (void)discoverManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:Localized(@"pleaseOpenBle") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [ac addAction:action];
        [self presentViewController:ac animated:YES completion:^{
            [self.animationTimer invalidate];
            self.animationTimer = nil;
        }];
    }
}

- (void)centralManagerDidStopScan:(CBCentralManager *)cm
{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        self.animationTimer.fireDate = NSDate.distantFuture;
        self.animationIV.userInteractionEnabled = YES;
        self.connectingLabel.text = Localized(@"connectFailed,tapImageReconnect");
    }
}

@end
