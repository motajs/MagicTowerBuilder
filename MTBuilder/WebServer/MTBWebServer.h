//
//  MTBWebServer.h
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTBWebServer : NSObject

@property (nonatomic, readonly) NSInteger port;

+ (instancetype)sharedServer;

- (instancetype)initWithPort:(NSInteger)port rootDirectory:(NSString *)rootDirectory;
- (BOOL)start;
- (void)stop;

@end
