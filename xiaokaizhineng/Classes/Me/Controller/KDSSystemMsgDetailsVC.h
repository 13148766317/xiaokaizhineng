//
//  KDSSystemMsgDetailsVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/3/8.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSTableViewController.h"
#import "KDSSysMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSSystemMsgDetailsVC : KDSTableViewController

///要展示的消息。
@property (nonatomic, copy) NSArray<KDSSysMessage *> *messages;

@end

NS_ASSUME_NONNULL_END
