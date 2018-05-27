//
//  MTBFolderInfo.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "MTBFolderInfo.h"

@implementation MTBFolderInfo

+ (NSURL *)currentWorkingDirectory
{
    static NSURL *folder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        folder = [[[NSBundle mainBundle] bundleURL] URLByDeletingLastPathComponent];
    });
    return folder;
}

@end
