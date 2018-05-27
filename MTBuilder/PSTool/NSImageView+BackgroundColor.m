//
//  NSImageView+BackgroundColor.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "NSImageView+BackgroundColor.h"
#import <objc/runtime.h>

#define ALPSwizzle(class, oriMethod, newMethod) {Method originalMethod = class_getInstanceMethod(class, @selector(oriMethod));\
Method swizzledMethod = class_getInstanceMethod(class, @selector(newMethod));\
if (class_addMethod(class, @selector(oriMethod), method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {\
class_replaceMethod(class, @selector(newMethod), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));\
} else {\
method_exchangeImplementations(originalMethod, swizzledMethod);\
}}

@implementation NSImageView (BackgroundColor)

+ (void)load
{
    ALPSwizzle(self, drawRect:, bc_drawRect:);
    ALPSwizzle(self, mouseDown:, bc_mouseDown:);
}

- (NSColor *)backgroundColor
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    objc_setAssociatedObject(self, @selector(backgroundColor), backgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (NSColor *)selectionBorderColor
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSelectionBorderColor:(NSColor *)selectionBorderColor
{
    objc_setAssociatedObject(self, @selector(selectionBorderColor), selectionBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (BOOL)drawPartBackground
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setDrawPartBackground:(BOOL)drawPartBackground
{
    objc_setAssociatedObject(self, @selector(drawPartBackground), @(drawPartBackground), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (NSSize)unitSize
{
    return [objc_getAssociatedObject(self, _cmd) sizeValue];
}

- (void)setUnitSize:(NSSize)unitSize
{
    objc_setAssociatedObject(self, @selector(unitSize), [NSValue valueWithSize:unitSize], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (NSPoint)selectedPosition
{
    NSValue *value = objc_getAssociatedObject(self, _cmd);
    return value ? [value pointValue] : NSMakePoint(-1, -1);
}

- (void)setSelectedPosition:(NSPoint)selectedPosition
{
    objc_setAssociatedObject(self, @selector(selectedPosition), [NSValue valueWithPoint:selectedPosition], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (void)bc_drawRect:(NSRect)dirtyRect
{
    if (self.backgroundColor) {
        [self.backgroundColor set];
        if (self.image && self.drawPartBackground) {
            [NSBezierPath fillRect:CGRectMake(0, self.bounds.size.height - self.image.size.height, self.image.size.width, self.image.size.height)];
        } else {
            [NSBezierPath fillRect:self.bounds];
        }
    }
    
    [self bc_drawRect:dirtyRect];
    
    if (self.selectionBorderColor && self.selectedPosition.x >= 0 && self.image) {
        [self.selectionBorderColor set];
        [NSBezierPath setDefaultLineWidth:3];
        [NSBezierPath strokeRect:NSMakeRect(self.selectedPosition.x * self.unitSize.width, self.bounds.size.height - self.selectedPosition.y * self.unitSize.height, self.unitSize.width, self.unitSize.height)];
    }
}

- (void)bc_mouseDown:(NSEvent *)event
{
    [self bc_mouseDown:event];
    if (self.unitSize.width != 0 && self.unitSize.height != 0) {
        NSPoint mousePosition = [self convertPoint:[event locationInWindow] fromView:self.window.contentView];
        if (mousePosition.x < self.image.size.width && mousePosition.y > self.bounds.size.height - self.image.size.height) {
            NSInteger xPos = floor(mousePosition.x / self.unitSize.width);
            NSInteger yPos = ceil((self.bounds.size.height - mousePosition.y) / self.unitSize.height);
            self.selectedPosition = NSMakePoint(xPos, yPos);
            [self becomeFirstResponder];
            [self setNeedsDisplay];
        }
    }
}

@end
