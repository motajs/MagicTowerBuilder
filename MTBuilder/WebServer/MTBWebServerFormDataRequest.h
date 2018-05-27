//
//  MTBWebServerFormDataRequest.h
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import <GCDWebServer/GCDWebServerDataRequest.h>

@interface MTBWebServerFormDataRequest : GCDWebServerDataRequest

@property (nonatomic, readonly) NSDictionary *arguments;

@end
