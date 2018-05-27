//
//  MTBWebServerFormDataRequest.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "MTBWebServerFormDataRequest.h"

@implementation MTBWebServerFormDataRequest

- (NSDictionary *)arguments
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    [[self.text componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger position = [obj rangeOfString:@"="].location;
        args[[obj substringToIndex:position]] = [obj substringFromIndex:position + 1];
    }];
    return args.copy;
}

@end
