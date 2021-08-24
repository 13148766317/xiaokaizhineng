//
//  NSString+extension.h
//  xiaokaizhineng
//
//  Created by orange on 2019/1/24.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (extension)

///字符串的md5。
@property (nonatomic, strong, readonly) NSString *md5;
///调用系统的接口生成一个UUID字符串。
@property (nonatomic, strong, class, readonly) NSString *uuid;

@end

NS_ASSUME_NONNULL_END
