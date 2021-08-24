//
//  KDSPwdListTableViewCell.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/11.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSPwdListTableViewCell.h"\

@implementation KDSPwdListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
-(void)setValueWithPwdListModel:(KDSPwdListModel*)model{
    self.nameLab.text = model.nickName ?: model.num;
    self.numberLab.text = model.num;
    NSLog(@"model.type====%lu",(unsigned long)model.type);
    if (model.type == KDSServerCycleTpyeCycle) {
        NSString *timeStr = @"密码将于每";
        NSMutableArray * weekDay = [[NSMutableArray alloc] init];
        [model.items enumerateObjectsUsingBlock:^(NSString *i,NSUInteger idx,BOOL*_Nonnullstop) {
            NSLog(@"%@",i);
            if (idx == 0 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周日,"];
            }else if(idx == 1 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周一,"];
            }else if(idx == 2 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周二,"];
            }else if(idx == 3 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周三,"];
            }else if(idx == 4 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周四,"];
            }else if(idx == 5 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周五,"];
            }else if(idx == 6 && [i isEqualToString:@"1"]) {
                [weekDay addObject:@"周六"];
            }
        }];
        if (weekDay.count == 7) {
            timeStr = [timeStr stringByAppendingPathComponent:@"天"];
        }else{
            for (NSString *str in weekDay) {
                timeStr = [timeStr stringByAppendingPathComponent:str];
            }
        }
        NSString *second = [[self time_timestampToStringWithHM:[model.startTime integerValue]] stringByAppendingString:[NSString stringWithFormat:@"-%@生效",[self time_timestampToStringWithHM:[model.endTime integerValue]]]];
        self.timeLab.text = [[timeStr stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByAppendingString:second];
    }else if (model.type == KDSServerCycleTpyePeriod || model.type == KDSServerCycleTpyeTwentyfourHours) {
        NSString *str = [NSString stringWithFormat:@"%@至%@",[self time_timestampToString:[model.startTime integerValue]],[self time_timestampToString:[model.endTime integerValue]]];
        NSString *s = [str stringByReplacingOccurrencesOfString:@"-"withString:@"/"];
        self.timeLab.text = [s stringByReplacingOccurrencesOfString:@"至" withString:@"-"];
    }else if (model.type == 1){
        self.timeLab.text = @"密码永久生效";
    }
}
///时间戳转化为字符转0000-00-00 00:00
-(NSString *)time_timestampToString:(NSInteger)timestamp{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString* string=[dateFormat stringFromDate:confromTimesp];
    return string;
}
///时间戳转化为字符转0000-00-00 00:00
-(NSString *)time_timestampToStringWithHM:(NSInteger)timestamp{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"HH:mm"];
    NSString* string=[dateFormat stringFromDate:confromTimesp];
    return string;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
