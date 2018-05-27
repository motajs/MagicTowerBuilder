//
//  NSImageView+BackgroundColor.h
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImageView (BackgroundColor)

@property (nonatomic, readwrite) NSColor *backgroundColor;
@property (nonatomic, readwrite) NSSize unitSize;
@property (nonatomic, readwrite) BOOL drawPartBackground;
@property (nonatomic, readwrite) NSPoint selectedPosition;
@property (nonatomic, readwrite) NSColor *selectionBorderColor;

@end
