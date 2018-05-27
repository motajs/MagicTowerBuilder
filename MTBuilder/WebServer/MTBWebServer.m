//
//  MTBWebServer.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "MTBWebServer.h"
#import <GCDWebServer.h>
#import <GCDWebServerDataResponse.h>
#import "MTBWebServerFormDataRequest.h"
#import "MTBFolderInfo.h"

@interface MTBWebServer()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, copy) NSString *rootDirectory;

@end

@implementation MTBWebServer

+ (instancetype)sharedServer
{
    static MTBWebServer *webServer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        webServer = [[MTBWebServer alloc] initWithPort:1055 rootDirectory:@"/Users/Iodine/Desktop"];
    });
    return webServer;
}

- (instancetype)initWithPort:(NSInteger)port rootDirectory:(NSString *)rootDirectory
{
    self = [super init];
    if (self) {
        _port = port;
        _rootDirectory = rootDirectory;
    }
    return self;
}

- (BOOL)start
{
    return [self.webServer startWithPort:self.port bonjourName:nil];
}

- (void)stop
{
    [self.webServer stop];
}

- (GCDWebServerResponse *)readFileRequest:(MTBWebServerFormDataRequest *)request
{
    NSString *type = request.arguments[@"type"];
    NSString *name = request.arguments[@"name"];
    if ([name containsString:@".."] || [name hasPrefix:@"/"]) {
        return [GCDWebServerResponse responseWithStatusCode:403];
    }
    NSData *data = [NSData dataWithContentsOfURL:[[MTBFolderInfo currentWorkingDirectory] URLByAppendingPathComponent:name]];
    if (!data) {
        return [GCDWebServerResponse responseWithStatusCode:404];
    }
    if ([type isEqualToString:@"utf8"]) {
        return [GCDWebServerDataResponse responseWithData:data contentType:[self contentTypeForExtension:name.pathExtension]];
    } else if ([type isEqualToString:@"base64"]) {
        return [GCDWebServerDataResponse responseWithText:[data base64EncodedStringWithOptions:0]];
    } else {
        return [GCDWebServerResponse responseWithStatusCode:400];
    }
}

- (GCDWebServerResponse *)writeFileRequest:(MTBWebServerFormDataRequest *)request
{
    NSString *type = request.arguments[@"type"];
    NSString *name = request.arguments[@"name"];
    NSString *value = request.arguments[@"value"];
    if ([name containsString:@".."] || [name hasPrefix:@"/"]) {
        return [GCDWebServerResponse responseWithStatusCode:403];
    }
    NSData *dataToWrite = nil;
    if ([type isEqualToString:@"utf8"]) {
        dataToWrite = [value dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([type isEqualToString:@"base64"]) {
        value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
        [value writeToFile:@"/Users/iodine/Desktop/request" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        dataToWrite = [[NSData alloc] initWithBase64EncodedString:value options:0];
    } else {
        return [GCDWebServerResponse responseWithStatusCode:400];
    }
    
    if ([dataToWrite writeToURL:[[MTBFolderInfo currentWorkingDirectory] URLByAppendingPathComponent:name] atomically:YES]) {
        return [GCDWebServerDataResponse responseWithText:@(dataToWrite.length).stringValue];
    } else {
        return [GCDWebServerDataResponse responseWithText:@"0"];
    }
}

- (GCDWebServerResponse *)listFileRequest:(MTBWebServerFormDataRequest *)request
{
    NSString *name = request.arguments[@"name"];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[MTBFolderInfo currentWorkingDirectory] URLByAppendingPathComponent:name].path isDirectory:&isDirectory]) {
        return [GCDWebServerResponse responseWithStatusCode:404];
    } else if (!isDirectory) {
        return [GCDWebServerResponse responseWithStatusCode:404];
    }
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[MTBFolderInfo currentWorkingDirectory] URLByAppendingPathComponent:name].path error:nil];
    
    return [GCDWebServerDataResponse responseWithJSONObject:contents];
}

- (NSString *)contentTypeForExtension:(NSString *)ext
{
    if ([ext isEqualToString:@"html"]) {
        return @"text/html";
    } else if ([ext isEqualToString:@"js"]) {
        return @"text/javascript";
    } else if ([ext isEqualToString:@"css"]) {
        return @"text/css";
    }
    return @"application/octet-stream";
}

- (GCDWebServer *)webServer
{
    if (!_webServer) {
        _webServer = [[GCDWebServer alloc] init];
        __weak typeof(self) weakWelf = self;
        [_webServer addGETHandlerForBasePath:@"/"
                               directoryPath:[MTBFolderInfo currentWorkingDirectory].path
                               indexFilename:@"index.html"
                                    cacheAge:0
                          allowRangeRequests:YES];
        [_webServer addHandlerForMethod:@"POST"
                                   path:@"/readFile"
                           requestClass:[MTBWebServerFormDataRequest class]
                           processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
                               return [weakWelf readFileRequest:request];
                           }];
        [_webServer addHandlerForMethod:@"POST"
                                   path:@"/writeFile"
                           requestClass:[MTBWebServerFormDataRequest class]
                           processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
                               return [weakWelf writeFileRequest:request];
                           }];
        [_webServer addHandlerForMethod:@"POST"
                                   path:@"/listFile"
                           requestClass:[MTBWebServerFormDataRequest class]
                           processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
                               return [weakWelf listFileRequest:request];
                           }];
    }
    return _webServer;
}

@end
