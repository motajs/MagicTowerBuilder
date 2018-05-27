//
//  MTBPSLaunchOptionsViewController.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "MTBPSLaunchOptionsViewController.h"
#import "MTBPSToolViewController.h"

@interface MTBPSLaunchOptionsViewController ()

@property (weak) IBOutlet NSPopUpButton *pixelSelectionButton;

@end

@implementation MTBPSLaunchOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"launch"]) {
        CGSize pixelUnitSize = CGSizeZero;
        if (self.pixelSelectionButton.selectedItem.tag == 1) {
            // 32 x 32
            pixelUnitSize = CGSizeMake(32, 32);
        } else if (self.pixelSelectionButton.selectedItem.tag == 2) {
            // 32 * 48
            pixelUnitSize = CGSizeMake(32, 48);
        }
        NSWindowController *windowController = segue.destinationController;
        [(MTBPSToolViewController *)windowController.contentViewController setPixelUnitSize:pixelUnitSize];
    }
}

@end
