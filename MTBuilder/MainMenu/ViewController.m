//
//  ViewController.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "ViewController.h"
#import "MTBWebServer.h"

@interface ViewController()
@property (weak) IBOutlet NSTextField *tipLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[MTBWebServer sharedServer] start]) {
        self.tipLabel.stringValue = [NSString stringWithFormat:@"已启动服务：http://localhost:%ld/", [MTBWebServer sharedServer].port];
    } else {
        self.tipLabel.stringValue = @"启动服务失败，请稍后再试";
    }
}

- (IBAction)startGame:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%ld/index.html", [MTBWebServer sharedServer].port]]];
}

- (IBAction)openMapEditor:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%ld/editor.html", [MTBWebServer sharedServer].port]]];
}

- (IBAction)openPSTool:(id)sender {
    
}

@end
