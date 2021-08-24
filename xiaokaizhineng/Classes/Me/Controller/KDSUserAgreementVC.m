//
//  KDSUserAgreementVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/25.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSUserAgreementVC.h"
#import "KDSHttpManager+User.h"
#import "MBProgressHUD+MJ.h"

@interface KDSUserAgreementVC ()

@end

@implementation KDSUserAgreementVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"userAgreement");
    //做条假的进度条。
    /*UIView *progressView = [[UIView alloc] initWithFrame:CGRectZero];
    progressView.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [self.view addSubview:progressView];
    [UIView animateWithDuration:2.0 animations:^{
        progressView.frame = CGRectMake(0, 0, kScreenWidth * 0.85, 2);
    }];
    void(^progressBlock) (void) = ^{
        [UIView animateWithDuration:0.1 animations:^{
            progressView.frame = CGRectMake(0, 0, kScreenWidth, 2);
        } completion:^(BOOL finished) {
            progressView.backgroundColor = self.view.backgroundColor;
        }];
    };
    KDSHttpManager *httpMgr = [KDSHttpManager sharedManager];
    [httpMgr getUserAgreementVersion:^(KDSUserAgreement * _Nonnull agreement) {
        
        [httpMgr getUserAgreementContentWithAgreement:agreement success:^(KDSUserAgreement * _Nonnull agreement) {
            progressBlock();
            NSString *content = agreement.content.length ? agreement.content : [NSString stringWithFormat:@"由于服务器没有返回协议内容，这是编造协议内容。协议名称：%@，协议id：%@，协议版本：%@，协议标签：%@", agreement.name, agreement._id, agreement.version, agreement.tag];
            UILabel *contentLabel = [[UILabel alloc] init];
            contentLabel.numberOfLines = 0;
            contentLabel.text = content;
            CGFloat height = ceil([content boundingRectWithSize:CGSizeMake(kScreenWidth - 40, 50000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : contentLabel.font} context:nil].size.height);
            contentLabel.frame = CGRectMake(20, 12, kScreenWidth - 40, height);
            [self.tableView addSubview:contentLabel];
            
            NSString *version = [NSString stringWithFormat:@"%@: %@", Localized(@"userAgreementVersion"), agreement.version];
            UILabel *verLabel = [[UILabel alloc] init];
            verLabel.frame = CGRectMake(20, CGRectGetMaxY(contentLabel.frame) + 50, kScreenWidth - 40, ceil([version sizeWithAttributes:@{NSFontAttributeName : verLabel.font}].height));
            verLabel.textAlignment = NSTextAlignmentRight;
            verLabel.text = version;
            [self.tableView addSubview:verLabel];
            
        } error:^(NSError * _Nonnull error) {
            progressBlock();
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.code]];
        } failure:^(NSError * _Nonnull error) {
            progressBlock();
            [MBProgressHUD showError:error.localizedDescription];
        }];
        
    } error:^(NSError * _Nonnull error) {
        progressBlock();
        [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.code]];
    } failure:^(NSError * _Nonnull error) {
        progressBlock();
        [MBProgressHUD showError:error.localizedDescription];
    }];
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(10);
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view).offset(-10);
    }];*/
    UITextView *textView = [[UITextView alloc] init];
    textView.editable = NO;
    textView.selectable = NO;
    textView.dataDetectorTypes = UIDataDetectorTypeNone;
    textView.textAlignment = NSTextAlignmentLeft;
    textView.attributedText = [self zhSimple];
    //CGRect bounds = [textView.attributedText boundingRectWithSize:CGSizeMake(kScreenWidth - 20, 50000) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    //textView.frame = (CGRect){0, 0, kScreenWidth - 20, bounds.size.height + 100};
    [self.view addSubview:textView];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.equalTo(self.view);
        make.left.mas_equalTo(self.view.mas_left).offset(10);
    }];
}

- (NSAttributedString *)zhSimple
{
    NSString *content = @"本协议系小凯（深圳）互联科技有限公司（以下简称“xiaokai”）与所有使用小凯智能客户端（以下简称“小凯”）的主体（包含但不限于个人、团队等）（以下简称用户）所订立的有效合约。使用小凯的任何服务即表示接受本协议的全部条款。\n\n一、总则\n1.1 小凯智能的所有权和运营权归小凯（深圳）互联科技有限公司。\n1.2 用户在注册之前，应当仔细阅读本协议，并同意遵守本协议后方可成为注册用户。一旦注册成功，则用户与小凯之间自动形成协议关系，用户应当受本协议的约束。用户在使用特殊的服务或产品时，应当同意接受相关协议后方能使用。\n1.3 本协议可由小凯智能随时更新，更新后的协议条款一旦公布即代替原来的协议条款，恕不再另行通知，用户可在本平台查阅最新版协议条款。在小凯智能修改协议条款后，如果用户不接受修改后的条款，请立即停止使用小凯提供的服务，用户继续使用小凯提供的服务将被视为接受修改后的协议。\n\n二、服务内容及使用须知\n2.1 小凯智能APP需配合小凯品牌相关产品使用。\n2.2 小凯智能仅提供相关的网络服务，除此之外与相关网络服务有关的设备(如个人电脑、手机、及其他与接入互联网或移动网有关的装置)及所需的费用(如为接入互联网而支付的电话费及上网费、为使用移动网而支付的手机费)均应由用户自行负担。\n\n三、用户账号\n3.1 经小凯智能注册系统完成注册程序并通过身份认证的用户即成为正式用户，可以获得小凯规定用户所应享有的一切权限。\n3.2 用户通过该账号所进行的一切活动引起的任何损失或损害，由用户自行承担全部责任，小凯智能不承担任何责任。因黑客行为或用户的保管疏忽导致账号非法使用，小凯不承担任何责任。\n\n四、使用规则\n4.1 用户需遵守中华人民共和国相关法律法规，包括但不限于《中华人民共和国计算机信息系统安全保护条例》、《计算机软件保护条例》、《最高人民法院关于审理涉及计算机网络著作权纠纷案件适用法律若干问题的解释(法释[2004]1号)》、《全国人大常委会关于维护互联网安全的决定》、《互联网电子公告服务管理规定》、《互联网新闻信息服务管理规定》、《互联网著作权行政保护办法》和《信息网络传播权保护条例》等有关计算机互联网规定和知识产权的法律和法规、实施办法。\n4.2 用户对其自行发表、上传或传送的内容负全部责任，所有用户不得在小凯智能任何页面发布、转载、传送含有下列内容之一的信息，否则小凯有权自行处理并不通知用户，且由此引起的任何损失或损害，由用户自行承担全部责任，小凯不承担任何责任：\n(1)违反宪法确定的基本原则的；\n(2)危害国家安全，泄漏国家机密，颠覆国家政权，破坏国家统一的；\n(3)损害国家荣誉和利益的；\n(4)煽动民族仇恨、民族歧视，破坏民族团结的；\n(5)破坏国家宗教政策，宣扬邪教和封建迷信的；\n(6)散布谣言，扰乱社会秩序，破坏社会稳定的；\n(7)散布淫秽、色情、赌博、暴力、恐怖或者教唆犯罪的；\n(8)侮辱或者诽谤他人，侵害他人合法权益的；\n(9)煽动非法集会、结社、游行、示威、聚众扰乱社会秩序的；\n(10)以非法民间组织名义活动的；\n(11)含有法律、行政法规禁止的其他内容的。\n4.3 用户承诺对其发表或者上传于小凯智能的所有信息(即属于《中华人民共和国著作权法》规定的作品，包括但不限于文字、图片、音乐、电影、表演和录音录像制品和电脑程序等)均享有完整的知识产权，或者已经得到相关权利人的合法授权；如用户违反本条规定造成小凯智能被第三人索赔的，用户应全额补偿小凯一切费用(包括但不限于各种赔偿费、诉讼代理费及为此支出的其它合理费用)，由此引起的任何损失或损害，由用户自行承担全部责任，小凯不承担任何责任；\n4.4 当第三方认为用户发表或者上传于小凯的信息侵犯其权利，并根据《信息网络传播权保护条例》或者相关法律规定向小凯发送权利通知书时，用户同意小凯可以自行判断决定删除涉嫌侵权信息，除非用户提交书面证据材料排除侵权的可能性，小凯将不会自动恢复上述删除的信息；\n4.5 用户保证，其向小凯智能上传的内容不得直接或间接的：\n(1)为任何非法目的而使用网络服务系统；\n(2)以任何方式干扰或企图干扰小凯智能客户端或小凯（深圳）互联科技有限公司网站的任何部分及功能的正常运行；\n(3)避开、尝试避开或声称能够避开任何内容保护机制或者小凯智能数据度量工具；\n(4)未获得小凯事先书面同意以书面格式或图形方式使用源自小凯（深圳）互联科技有限公司的任何注册或未注册的作品、服务标志、公司徽标（LOGO）、URL或其他标志；\n(5)请求、收集、索取或以其他方式从任何用户那里获取对小凯智能科技账号、密码或其他身份验证凭据的访问权；\n(6)为任何用户自动登录到小凯智能账号代理身份验证凭据；\n(7)提供跟踪功能，包括但不限于识别其他用户在个人主页上查看或操作；\n(8)未经授权冒充他人获取对小凯智能科技的访问权。\n4.6 用户违反上述任何一款的保证，小凯均有权就其情节对其做出警告、屏蔽直至取消登录资格的处罚；如因用户违反上述保证而给小凯、小凯智能用户或小凯（深圳）互联科技有限公司的任何合作伙伴造成损失，用户自行负责承担一切法律责任并赔偿损失。\n\n五、隐私保护\n5.1 小凯智能不对外公开或向第三方提供单个用户的注册资料及用户在使用网络服务时存储在小凯智能的非公开内容，但下列情况除外：\n(1)事先获得用户的明确授权；\n(2)根据有关的法律法规要求；\n(3)按照相关政府主管部门的要求；\n(4)为维护社会公众的利益。\n5.2 小凯智能可能会与第三方合作向用户提供相关的网络服务，在此情况下，如该第三方同意承担与小凯智能同等的保护用户隐私的责任，则小凯智能有权将用户的注册资料等提供给该第三方。\n5.3 在不透露单个用户隐私资料的前提下，小凯智能有权对整个用户数据库进行分析并对用户数据库进行商业上的利用。\n\n六、版权声明\n6.1 小凯智能的文字、图片、音频、视频等版权均归小凯（深圳）互联科技有限公司享有或与作者共同享有，未经小凯智能许可，不得任意转载，否则将承担相关法律责任。\n6.2 小凯智能特有的标识、版面设计、编排方式等版权均属小凯（深圳）互联科技有限公司享有，未经小凯智能许可，不得任意复制或转载。\n6.3 使用小凯智能的任何内容均应注明“来源于小凯智能”及署上作者姓名，按法律规定需要支付稿酬的，应当通知小凯智能及作者并支付稿酬，并独立承担一切法律责任。\n6.4 小凯智能享有所有作品用于其它用途的优先权，包括但不限于网站、电子杂志、平面出版等，但在使用前会通知作者，并按同行业的标准支付稿酬。\n6.5 小凯智能所有内容仅代表作者自己的立场和观点，与小凯无关，由作者本人承担一切法律责任。\n6.6 恶意转载小凯智能内容的，小凯保留将其诉诸法律的权利。\n\n七、责任声明\n7.1 用户明确同意其使用小凯智能网络服务所存在的风险及一切后果将完全由用户本人承担，小凯对此不承担任何责任。\n7.2 小凯智能无法保证网络服务一定能满足用户的要求，也不保证网络服务的及时性、安全性、准确性。\n7.3 小凯智能不保证为方便用户而设置的外部链接的准确性和完整性，同时，对于该等外部链接指向的不由小凯智能实际控制的任何网页上的内容，小凯智能不承担任何责任。\n7.4对于小凯智能向用户提供的下列产品或者服务的质量缺陷本身及其引发的任何损失，小凯智能无需承担任何责任：\n(1)小凯智能向用户免费提供的各项网络服务；\n(2)小凯智能向用户赠送的任何产品或者服务。终止本服务(或其任何部分)，而无论其通知与否，小凯智能对用户和任何第三人均无需承担任何责任。\n\n八、附则\n8.1 本协议的订立、执行和解释及争议的解决均应适用中华人民共和国法律。如用户和优点科技就本协议内容或其执行发生任何争议，双方应尽量友好协商解决；协商不成时，任何一方均可向小凯所在地的人民法院提起诉讼。\n8.2本协议一经公布即生效，小凯有权随时对协议内容进行修改，修改后的结果公布于小凯（深圳）互联科技有限公司网站上。如果不同意小凯对本协议相关条款所做的修改，用户有权停止使用网络服务。如果用户继续使用网络服务，则视为用户接受小凯（深圳）互联科技有限公司对本协议相关条款所做的修改。\n8.3 如本协议中的任何条款无论因何种原因完全或部分无效或不具有执行力，本协议的其余条款仍应有效并且有约束力。\n8.4不可抗力条款：如果不能履行本协议是由于一方所不能预见和控制的原因造成的，如战争、罢工、自然灾害、恶劣天气、航空运输中断等，则不能履行本协议的一方可相应免责。\n8.5 本协议解释权及修订权归小凯（深圳）互联科技有限公司。\n\n";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 10; //行距
    //标题
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont systemFontOfSize:17], NSForegroundColorAttributeName:KDSRGBColor(45, 217, 186),NSParagraphStyleAttributeName:paragraphStyle};
    //内容
    NSDictionary * attrs1 = @{NSFontAttributeName:[UIFont systemFontOfSize:15], NSForegroundColorAttributeName:KDSRGBColor(102, 102, 102),NSParagraphStyleAttributeName:paragraphStyle};
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:content];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"一、总则"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"二、服务内容及使用须知"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"三、用户账号"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"四、使用规则"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"五、隐私保护"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"六、版权声明"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"七、责任声明"]];
    [attrStr addAttributes:attrs range:[content rangeOfString:@"八、附则"]];
    
    [attrStr addAttributes:attrs1 range:[content rangeOfString:@"本协议系小凯（深圳）互联科技有限公司（以下简称“xiaokai”）与所有使用小凯智能客户端（以下简称“小凯”）的主体（包含但不限于个人、团队等）（以下简称用户）所订立的有效合约。使用小凯的任何服务即表示接受本协议的全部条款。"]];
    [attrStr addAttributes:attrs1 range:[content rangeOfString:@"1.1 小凯智能的所有权和运营权归小凯（深圳）互联科技有限公司。\n1.2 用户在注册之前，应当仔细阅读本协议，并同意遵守本协议后方可成为注册用户。一旦注册成功，则用户与小凯之间自动形成协议关系，用户应当受本协议的约束。用户在使用特殊的服务或产品时，应当同意接受相关协议后方能使用。\n1.3 本协议可由小凯智能随时更新，更新后的协议条款一旦公布即代替原来的协议条款，恕不再另行通知，用户可在本平台查阅最新版协议条款。在小凯智能修改协议条款后，如果用户不接受修改后的条款，请立即停止使用小凯提供的服务，用户继续使用小凯提供的服务将被视为接受修改后的协议。"]];
    [attrStr addAttributes:attrs1 range:[content rangeOfString:@"2.1 小凯智能APP需配合小凯品牌相关产品使用。\n2.2 小凯智能仅提供相关的网络服务，除此之外与相关网络服务有关的设备(如个人电脑、手机、及其他与接入互联网或移动网有关的装置)及所需的费用(如为接入互联网而支付的电话费及上网费、为使用移动网而支付的手机费)均应由用户自行负担。"]];
    [attrStr addAttributes:attrs1 range:[content rangeOfString:@"3.1 经小凯智能注册系统完成注册程序并通过身份认证的用户即成为正式用户，可以获得小凯规定用户所应享有的一切权限。\n3.2 用户通过该账号所进行的一切活动引起的任何损失或损害，由用户自行承担全部责任，小凯智能不承担任何责任。因黑客行为或用户的保管疏忽导致账号非法使用，小凯不承担任何责任。"]];
    [attrStr addAttributes:attrs1 range:[content rangeOfString:@"4.1 用户需遵守中华人民共和国相关法律法规，包括但不限于《中华人民共和国计算机信息系统安全保护条例》、《计算机软件保护条例》、《最高人民法院关于审理涉及计算机网络著作权纠纷案件适用法律若干问题的解释(法释[2004]1号)》、《全国人大常委会关于维护互联网安全的决定》、《互联网电子公告服务管理规定》、《互联网新闻信息服务管理规定》、《互联网著作权行政保护办法》和《信息网络传播权保护条例》等有关计算机互联网规定和知识产权的法律和法规、实施办法。\n4.2 用户对其自行发表、上传或传送的内容负全部责任，所有用户不得在小凯智能任何页面发布、转载、传送含有下列内容之一的信息，否则小凯有权自行处理并不通知用户，且由此引起的任何损失或损害，由用户自行承担全部责任，小凯不承担任何责任：\n(1)违反宪法确定的基本原则的；\n(2)危害国家安全，泄漏国家机密，颠覆国家政权，破坏国家统一的；\n(3)损害国家荣誉和利益的；\n(4)煽动民族仇恨、民族歧视，破坏民族团结的；\n(5)破坏国家宗教政策，宣扬邪教和封建迷信的；\n(6)散布谣言，扰乱社会秩序，破坏社会稳定的；\n(7)散布淫秽、色情、赌博、暴力、恐怖或者教唆犯罪的；\n(8)侮辱或者诽谤他人，侵害他人合法权益的；\n(9)煽动非法集会、结社、游行、示威、聚众扰乱社会秩序的；\n(10)以非法民间组织名义活动的；\n(11)含有法律、行政法规禁止的其他内容的。\n4.3 用户承诺对其发表或者上传于小凯智能的所有信息(即属于《中华人民共和国著作权法》规定的作品，包括但不限于文字、图片、音乐、电影、表演和录音录像制品和电脑程序等)均享有完整的知识产权，或者已经得到相关权利人的合法授权；如用户违反本条规定造成小凯智能被第三人索赔的，用户应全额补偿小凯一切费用(包括但不限于各种赔偿费、诉讼代理费及为此支出的其它合理费用)，由此引起的任何损失或损害，由用户自行承担全部责任，小凯不承担任何责任；\n4.4 当第三方认为用户发表或者上传于小凯的信息侵犯其权利，并根据《信息网络传播权保护条例》或者相关法律规定向小凯发送权利通知书时，用户同意小凯可以自行判断决定删除涉嫌侵权信息，除非用户提交书面证据材料排除侵权的可能性，小凯将不会自动恢复上述删除的信息；\n4.5 用户保证，其向小凯智能上传的内容不得直接或间接的：\n(1)为任何非法目的而使用网络服务系统；\n(2)以任何方式干扰或企图干扰小凯智能客户端或小凯（深圳）互联科技有限公司网站的任何部分及功能的正常运行；\n(3)避开、尝试避开或声称能够避开任何内容保护机制或者小凯智能数据度量工具；\n(4)未获得小凯事先书面同意以书面格式或图形方式使用源自小凯（深圳）互联科技有限公司的任何注册或未注册的作品、服务标志、公司徽标（LOGO）、URL或其他标志；\n(5)请求、收集、索取或以其他方式从任何用户那里获取对小凯智能科技账号、密码或其他身份验证凭据的访问权；\n(6)为任何用户自动登录到小凯智能账号代理身份验证凭据；\n(7)提供跟踪功能，包括但不限于识别其他用户在个人主页上查看或操作；\n(8)未经授权冒充他人获取对小凯智能科技的访问权。\n4.6 用户违反上述任何一款的保证，小凯均有权就其情节对其做出警告、屏蔽直至取消登录资格的处罚；如因用户违反上述保证而给小凯、小凯智能用户或小凯（深圳）互联科技有限公司的任何合作伙伴造成损失，用户自行负责承担一切法律责任并赔偿损失。"]];
     [attrStr addAttributes:attrs1 range:[content rangeOfString:@"5.1 小凯智能不对外公开或向第三方提供单个用户的注册资料及用户在使用网络服务时存储在小凯智能的非公开内容，但下列情况除外：\n(1)事先获得用户的明确授权；\n(2)根据有关的法律法规要求；\n(3)按照相关政府主管部门的要求；\n(4)为维护社会公众的利益。\n5.2 小凯智能可能会与第三方合作向用户提供相关的网络服务，在此情况下，如该第三方同意承担与小凯智能同等的保护用户隐私的责任，则小凯智能有权将用户的注册资料等提供给该第三方。\n5.3 在不透露单个用户隐私资料的前提下，小凯智能有权对整个用户数据库进行分析并对用户数据库进行商业上的利用。"]];
     [attrStr addAttributes:attrs1 range:[content rangeOfString:@"6.1 小凯智能的文字、图片、音频、视频等版权均归小凯（深圳）互联科技有限公司享有或与作者共同享有，未经小凯智能许可，不得任意转载，否则将承担相关法律责任。\n6.2 小凯智能特有的标识、版面设计、编排方式等版权均属小凯（深圳）互联科技有限公司享有，未经小凯智能许可，不得任意复制或转载。\n6.3 使用小凯智能的任何内容均应注明“来源于小凯智能”及署上作者姓名，按法律规定需要支付稿酬的，应当通知小凯智能及作者并支付稿酬，并独立承担一切法律责任。\n6.4 小凯智能享有所有作品用于其它用途的优先权，包括但不限于网站、电子杂志、平面出版等，但在使用前会通知作者，并按同行业的标准支付稿酬。\n6.5 小凯智能所有内容仅代表作者自己的立场和观点，与小凯无关，由作者本人承担一切法律责任。\n6.6 恶意转载小凯智能内容的，小凯保留将其诉诸法律的权利。"]];
     [attrStr addAttributes:attrs1 range:[content rangeOfString:@"7.1 用户明确同意其使用小凯智能网络服务所存在的风险及一切后果将完全由用户本人承担，小凯对此不承担任何责任。\n7.2 小凯智能无法保证网络服务一定能满足用户的要求，也不保证网络服务的及时性、安全性、准确性。\n7.3 小凯智能不保证为方便用户而设置的外部链接的准确性和完整性，同时，对于该等外部链接指向的不由小凯智能实际控制的任何网页上的内容，小凯智能不承担任何责任。\n7.4对于小凯智能向用户提供的下列产品或者服务的质量缺陷本身及其引发的任何损失，小凯智能无需承担任何责任：\n(1)小凯智能向用户免费提供的各项网络服务；\n(2)小凯智能向用户赠送的任何产品或者服务。终止本服务(或其任何部分)，而无论其通知与否，小凯智能对用户和任何第三人均无需承担任何责任。"]];
     [attrStr addAttributes:attrs1 range:[content rangeOfString:@"8.1 本协议的订立、执行和解释及争议的解决均应适用中华人民共和国法律。如用户和优点科技就本协议内容或其执行发生任何争议，双方应尽量友好协商解决；协商不成时，任何一方均可向小凯所在地的人民法院提起诉讼。\n8.2本协议一经公布即生效，小凯有权随时对协议内容进行修改，修改后的结果公布于小凯（深圳）互联科技有限公司网站上。如果不同意小凯对本协议相关条款所做的修改，用户有权停止使用网络服务。如果用户继续使用网络服务，则视为用户接受小凯（深圳）互联科技有限公司对本协议相关条款所做的修改。\n8.3 如本协议中的任何条款无论因何种原因完全或部分无效或不具有执行力，本协议的其余条款仍应有效并且有约束力。\n8.4不可抗力条款：如果不能履行本协议是由于一方所不能预见和控制的原因造成的，如战争、罢工、自然灾害、恶劣天气、航空运输中断等，则不能履行本协议的一方可相应免责。\n8.5 本协议解释权及修订权归小凯（深圳）互联科技有限公司。"]];
    
    return attrStr;
}

@end
