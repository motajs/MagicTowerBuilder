//
//  MTBPSToolViewController.m
//  MTBuilder
//
//  Created by 熊典 on 2018/5/26.
//  Copyright © 2018年 熊典. All rights reserved.
//

#import "MTBPSToolViewController.h"
#import "NSImageView+BackgroundColor.h"
#import "MTBFolderInfo.h"
#import <CoreImage/CIFilter.h>

@interface MTBPSToolViewController ()

@property (weak) IBOutlet NSImageView *leftImageView;
@property (weak) IBOutlet NSImageView *rightImageView;
@property (weak) IBOutlet NSTextField *tipLabel;
@property (weak) IBOutlet NSImageView *pasteboardImageView;
@property (weak) IBOutlet NSSlider *hueSlider;

@property (nonatomic, strong) NSImage *rightImage;
@property (nonatomic, copy) void (^revertAction)(void);
@property (nonatomic, copy) NSString *leftFilename;
@property (nonatomic, strong) NSMutableDictionary *hueCache;

@property (weak) IBOutlet NSButton *buttonSaveImage;
@property (weak) IBOutlet NSButton *buttonAddNewLine;
@property (weak) IBOutlet NSButton *buttonMultipleApply;

@end

@implementation MTBPSToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leftImageView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"transparent_background"]];
    self.rightImageView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"transparent_background"]];
    self.pasteboardImageView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"transparent_background"]];
    self.leftImageView.selectionBorderColor = [NSColor redColor];
    self.rightImageView.selectionBorderColor = [NSColor redColor];
    self.leftImageView.drawPartBackground = YES;
    self.rightImageView.drawPartBackground = YES;
    
    self.buttonSaveImage.enabled = NO;
    self.buttonAddNewLine.enabled = NO;
    self.buttonMultipleApply.enabled = NO;
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        if (!self.view.window.isKeyWindow) {
            return event;
        }
        
        NSImageView *activeImageView = nil;
        if (self.leftImageView.selectedPosition.x >= 0) {
            activeImageView = self.leftImageView;
        } else if (self.rightImageView.selectedPosition.x >= 0) {
            activeImageView = self.rightImageView;
        }
        
        if (!activeImageView) {
            return event;
        }
        if ([event.characters isEqualToString:@"c"]) {
            NSImage *image = [[NSImage alloc] initWithSize:self.pixelUnitSize];
            [image lockFocus];
            [activeImageView.image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(activeImageView.selectedPosition.x * self.pixelUnitSize.width, activeImageView.image.size.height - activeImageView.selectedPosition.y * self.pixelUnitSize.height, self.pixelUnitSize.width, self.pixelUnitSize.height) operation:NSCompositingOperationSourceOver fraction:1];
            [image unlockFocus];
            self.pasteboardImageView.image = image;
        } else if ([event.characters isEqualToString:@"v"]) {
            if (!self.pasteboardImageView.image) {
                return event;
            }
            if (activeImageView == self.rightImageView) {
                return event;
            }
            NSImage *image = activeImageView.image;
            [self saveState];
            [image lockFocus];
            [self.pasteboardImageView.image drawAtPoint:NSMakePoint(activeImageView.selectedPosition.x * self.pixelUnitSize.width, activeImageView.image.size.height - activeImageView.selectedPosition.y * self.pixelUnitSize.height) fromRect:NSZeroRect operation:NSCompositingOperationClear fraction:1];
            [self.pasteboardImageView.image drawAtPoint:NSMakePoint(activeImageView.selectedPosition.x * self.pixelUnitSize.width, activeImageView.image.size.height - activeImageView.selectedPosition.y * self.pixelUnitSize.height) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
            [image unlockFocus];
            [activeImageView setNeedsDisplay];
        } else if ([event.characters isEqualToString:@"z"]) {
            if (self.revertAction) {
                self.revertAction();
                self.revertAction = nil;
            }
        }
        return event;
    }];
}

- (void)saveState
{
    NSImage *originImage = self.leftImageView.image.copy;
    __weak typeof(self) weakSelf = self;
    self.revertAction = ^{
        weakSelf.leftImageView.image = originImage;
    };
}

- (void)mouseDown:(NSEvent *)event
{
    [super mouseDown:event];
    NSPoint location = [event locationInWindow];
    if ([self point:location insideRect:[self.view.window.contentView convertRect:self.leftImageView.superview.bounds fromView:self.leftImageView.superview]]) {
        self.rightImageView.selectedPosition = NSMakePoint(-1, -1);
    } else if ([self point:location insideRect:[self.view.window.contentView convertRect:self.rightImageView.superview.bounds fromView:self.rightImageView.superview]]) {
        self.leftImageView.selectedPosition = NSMakePoint(-1, -1);
    } else {
        self.leftImageView.selectedPosition = NSMakePoint(-1, -1);
        self.rightImageView.selectedPosition = NSMakePoint(-1, -1);
    }
}

- (BOOL)point:(NSPoint)p insideRect:(NSRect)rect
{
    return p.x > rect.origin.x && p.x < rect.origin.x + rect.size.width && p.y > rect.origin.y && p.y < rect.origin.y + rect.size.height;
}

- (void)setPixelUnitSize:(CGSize)pixelUnitSize
{
    _pixelUnitSize = pixelUnitSize;
    self.leftImageView.unitSize = pixelUnitSize;
    self.rightImageView.unitSize = pixelUnitSize;
    self.tipLabel.stringValue = [NSString stringWithFormat:@"使用说明：\n在一边选中某个位置的图标后，按 ⌘C 复制到剪切板\n在另一边选中需要的位置 ⌘V 即可粘贴并覆盖\n⌘Z 可回退到上一步粘贴操作前\n本工具只支持 %.0fx%.0f 像素的操作，敬请谅解。", self.pixelUnitSize.width, self.pixelUnitSize.height];
}

- (void)openImageWithCompletionHandler:(void (^)(NSImage *image, NSString *filename))completionHandler
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.directoryURL = [[MTBFolderInfo currentWorkingDirectory] URLByAppendingPathComponent:@"project/images"];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.allowedFileTypes = @[@"jpg", @"jpeg", @"png"];
    openPanel.allowsOtherFileTypes = NO;
    
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSImage *adjustedImage = [self suitableImageForImage:[[NSImage alloc] initWithContentsOfURL:openPanel.URLs.firstObject]];
            if (adjustedImage) {
                if (completionHandler) {
                    completionHandler(adjustedImage, openPanel.URLs.firstObject.lastPathComponent);
                }
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"打开失败";
                alert.informativeText = @"图片的尺寸不符合要求";
                [alert addButtonWithTitle:@"好"];
                [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                    if (completionHandler) {
                        completionHandler(nil, nil);
                    }
                }];
            }
        }
    }];
}

- (NSImage *)suitableImageForImage:(NSImage *)image
{
    CGImageRef imageRef = [image CGImageForProposedRect:nil context:nil hints:nil];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    uint8 *data = calloc(4 * width, height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
    
    NSInteger alphaCount = 0;
    NSInteger whiteCount = 0;
    for (int byte = 0; byte < 4 * width * height; byte += 4) {
        uint8 r = data[byte];
        uint8 g = data[byte + 1];
        uint8 b = data[byte + 2];
        uint8 a = data[byte + 3];
        if (a == 0) {
            alphaCount++;
        } else if (r == 0xFF && g == 0xFF && b == 0xFF) {
            whiteCount++;
        }
    }
    
    if (whiteCount > alphaCount * 10) {
        for (int byte = 0; byte < 4 * width * height; byte += 4) {
            uint8 r = data[byte];
            uint8 g = data[byte + 1];
            uint8 b = data[byte + 2];
            uint8 a = data[byte + 3];
            if (r >= 0xFA && g >= 0xFA && b >= 0xFA && a == 0xFF) {
                data[byte + 3] = 0;
            }
        }
    }
    
    CGImageRef resultImage = CGBitmapContextCreateImage(ctx);
    NSImage *resultImageObj = [[NSImage alloc] initWithCGImage:resultImage size:NSMakeSize(width, height)];
    CGImageRelease(resultImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(data);
    
    size_t unitWidth = self.pixelUnitSize.width;
    size_t unitHeight = self.pixelUnitSize.height;
    
    if (width % unitWidth != 0 || height % unitHeight != 0) {
        if (width <= unitWidth * 4 && height <= unitHeight * 4) {
            width = unitWidth * 4;
            height = unitHeight * 4;
        } else {
            return nil;
        }
    }
    
    return [self imageResize:resultImageObj newSize:NSMakeSize(width, height)];
}

- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    if (anImage.size.width == newSize.width && anImage.size.height == newSize.height) {
        return anImage;
    }
    NSImage *sourceImage = anImage;
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositingOperationCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

- (IBAction)selectPictureForLeft:(id)sender {
    [self openImageWithCompletionHandler:^(NSImage *image, NSString *filename) {
        self.leftFilename = filename;
        [self setImage:image forImageView:self.leftImageView];
        self.buttonSaveImage.enabled = YES;
        self.buttonAddNewLine.enabled = YES;
        [self renewMultipleApplyEnable];
    }];
}

- (void)renewMultipleApplyEnable
{
    if (!self.rightImage || !self.leftImageView.image) {
        self.buttonMultipleApply.enabled = NO;
        return;
    }
    NSInteger leftCols = self.leftImageView.image.size.width / self.pixelUnitSize.width;
    self.buttonMultipleApply.enabled = self.rightImage.size.width == self.pixelUnitSize.width * 4 && self.rightImage.size.height == self.pixelUnitSize.height * 4 && (leftCols == 2 || leftCols == 4);
}

- (IBAction)selectPictureForRight:(id)sender {
    [self openImageWithCompletionHandler:^(NSImage *image, NSString *filename) {
        self.rightImage = image;
        [self calculateHueCache];
        [self setImage:image forImageView:self.rightImageView];
        [self renewMultipleApplyEnable];
    }];
}

- (void)calculateHueCache
{
    self.hueCache = [NSMutableDictionary dictionary];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i = 0; i < 12; i++) {
            NSImage *adjustedImage = [self adjustImage:self.rightImage withHue:1.0 * i / 12 * M_PI * 2];
            self.hueCache[@(i)] = adjustedImage;
        }
        self.hueCache[@(12)] = self.hueCache[@(0)];
    });
}

- (IBAction)addNewLineForLeft:(id)sender {
    [self saveState];
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(self.leftImageView.image.size.width, self.leftImageView.image.size.height + self.pixelUnitSize.height)];
    [newImage lockFocus];
    [self.leftImageView.image drawAtPoint:NSMakePoint(0, self.pixelUnitSize.height) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [newImage unlockFocus];
    [self setImage:newImage forImageView:self.leftImageView];
}

- (void)setImage:(NSImage *)image forImageView:(NSImageView *)imageView
{
    imageView.selectedPosition = NSMakePoint(-1, -1);
    self.hueSlider.integerValue = 0;
    imageView.image = image;
    CGRect frame = imageView.frame;
    frame.size.width = MAX(imageView.image.size.width, imageView.superview.bounds.size.width);
    frame.size.height = MAX(imageView.image.size.height, imageView.superview.bounds.size.height);
    imageView.frame = frame;
}

- (IBAction)savePictureForLeft:(id)sender {
    if (!self.leftImageView.image) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"无法保存";
        alert.informativeText = @"清先打开一张图片";
        [alert addButtonWithTitle:@"好"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        return;
    }
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[@"png"];
    savePanel.nameFieldStringValue = self.leftFilename;
    savePanel.directoryURL = [[MTBFolderInfo currentWorkingDirectory] URLByAppendingPathComponent:@"project/images"];
    [savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSData *imageData = [self.leftImageView.image TIFFRepresentation];
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
            [imageRep setSize:self.leftImageView.image.size];
            [[imageRep representationUsingType:NSPNGFileType properties:@{}] writeToURL:savePanel.URL atomically:YES];
        }
    }];
}
- (IBAction)hueChanged:(id)sender {
    if (!self.rightImage) {
        return;
    }
    if (self.hueCache[@(self.hueSlider.integerValue)]) {
        self.rightImageView.image = self.hueCache[@(self.hueSlider.integerValue)];
    } else {
        self.rightImageView.image = [self adjustImage:self.rightImage withHue:1.0 * self.hueSlider.integerValue / 12 * M_PI * 2];
    }
}

- (NSImage*)adjustImage:(NSImage*)img withHue:(float)hue {
    CGImageRef imageRef = [img CGImageForProposedRect:nil context:nil hints:nil];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    uint8 *data = calloc(4 * width, height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
    
    for (NSInteger byte = 0; byte < width * height * 4; byte += 4) {
        uint8 r = data[byte];
        uint8 g = data[byte + 1];
        uint8 blue = data[byte + 2];
        
        float nH, nS, nL, nR, nG, nB, ndelR, ndelG, ndelB, nmax, nmin, ndelMax;
        
        CGFloat h, s, b;
        
        nR = (r / 255.f);
        nG = (g / 255.f);
        nB = (blue / 255.f);
        nmax = MAX(MAX(nR, nG), nB);
        nmin = MIN(MIN(nR, nG), nB);
        ndelMax = nmax - nmin;
        nL = (nmax + nmin) / 2;
        
        if (ndelMax == 0) {
            nH = 0;
            nS = 0;
        } else {
            if (nL < 0.5) {
                nS = ndelMax / (nmax + nmin);
            } else {
                nS = ndelMax / (2 - nmax - nmin);
            }
            ndelR = (((nmax - nR) / 6) + (ndelMax / 2)) / ndelMax;
            ndelG = (((nmax - nG) / 6) + (ndelMax / 2)) / ndelMax;
            ndelB = (((nmax - nB) / 6) + (ndelMax / 2)) / ndelMax;
            if (nR == nmax) {
                nH = ndelB - ndelG;
            } else if (nG == nmax) {
                nH = (1.0 / 3) + ndelR - ndelB;
            } else if (nB == nmax) {
                nH = (2.0 / 3) + ndelG - ndelR;
            } else {
                nH = 0;
            }
            if (nH < 0) {
                nH = nH + 1;
            } else if (nH > 1) {
                nH = nH - 1;
            }
        }
        
        h = nH * M_PI * 2;
        s = nS;
        b = nL;
        
        h += hue;
        
        h = h / M_PI * 180;
        if (h > 360) {
            h -= 360;
        }
        
        CGFloat fMax, fMid, fMin;
        uint8 iSextant, iMax, iMid, iMin;
        
        if (0.5 < b) {
            fMax = b - (b * s) + s;
            fMin = b + (b * s) - s;
        } else {
            fMax = b + (b * s);
            fMin = b - (b * s);
        }
        
        iSextant = (int)floor(h / 60.f);
        if (300 <= h)
        {
            h -= 360;
        }
        h /= 60.f;
        h -= 2.f * (float)floor(((iSextant + 1) % 6) / 2.f);
        if (0 == iSextant % 2)
        {
            fMid = h * (fMax - fMin) + fMin;
        }
        else
        {
            fMid = fMin - h * (fMax - fMin);
        }
        
        iMax = fMax * 255;
        iMid = fMid * 255;
        iMin = fMin * 255;
        
        switch (iSextant) {
            case 1:
                r = iMid;
                g = iMax;
                blue = iMin;
                break;
            case 2:
                r = iMin;
                g = iMax;
                blue = iMid;
                break;
            case 3:
                r = iMin;
                g = iMid;
                blue = iMax;
                break;
            case 4:
                r = iMid;
                g = iMin;
                blue = iMax;
                break;
            case 5:
                r = iMax;
                g = iMin;
                blue = iMid;
                break;
            case 6:
                r = iMax;
                g = iMid;
                blue = iMin;
                break;
                
            default:
                break;
        }
        
        data[byte] = r;
        data[byte + 1] = g;
        data[byte + 2] = blue;
    }
    
    CGImageRef resultImage = CGBitmapContextCreateImage(ctx);
    NSImage *resultImageObj = [[NSImage alloc] initWithCGImage:resultImage size:NSMakeSize(width, height)];
    CGImageRelease(resultImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(data);
    
    return [self imageResize:resultImageObj newSize:self.rightImage.size];
}
- (IBAction)multipleApply:(id)sender {
    [self saveState];
    NSInteger leftCols = self.leftImageView.image.size.width / self.pixelUnitSize.width;
    if (leftCols == 4) {
        NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(self.leftImageView.image.size.width, self.leftImageView.image.size.height + self.rightImageView.image.size.height)];
        [newImage lockFocus];
        [self.rightImageView.image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [self.leftImageView.image drawAtPoint:NSMakePoint(0, self.rightImageView.image.size.height) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [newImage unlockFocus];
        [self setImage:newImage forImageView:self.leftImageView];
    } else if (leftCols == 2) {
        NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(self.leftImageView.image.size.width, self.leftImageView.image.size.height + self.rightImageView.image.size.height)];
        [newImage lockFocus];
        
        CGImageRef imageRef = [self.rightImageView.image CGImageForProposedRect:nil context:nil hints:nil];
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        uint8 *data = calloc(4 * width, height);
        CGFloat scale = self.view.window.backingScaleFactor;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
            
        for (NSInteger row = 0; row < 4; row++) {
            [self.rightImageView.image drawAtPoint:NSMakePoint(0, row * self.pixelUnitSize.height) fromRect:NSMakeRect(0, row * self.pixelUnitSize.height, self.pixelUnitSize.width, self.pixelUnitSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];
            BOOL isSame = YES;
            for (NSInteger x = 0; x < self.pixelUnitSize.height * scale; x++) {
                for (NSInteger y = 0; y < self.pixelUnitSize.width * scale; y++) {
                    uint8 data1 = data[(int)((row * self.pixelUnitSize.height * scale + x) * width * 4 + y * 4)];
                    uint8 data2 = data[(int)((row * self.pixelUnitSize.height * scale + x) * width * 4 + (self.pixelUnitSize.width * scale + y) * 4)];
                    if (data1 != data2) {
                        isSame = NO;
                        break;
                    }
                }
                if (!isSame) {
                    break;
                }
            }
            if (isSame) {
                [self.rightImageView.image drawAtPoint:NSMakePoint(self.pixelUnitSize.width, row * self.pixelUnitSize.height) fromRect:NSMakeRect(self.pixelUnitSize.width * 2, row * self.pixelUnitSize.height, self.pixelUnitSize.width, self.pixelUnitSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];
            } else {
                [self.rightImageView.image drawAtPoint:NSMakePoint(self.pixelUnitSize.width, row * self.pixelUnitSize.height) fromRect:NSMakeRect(self.pixelUnitSize.width, row * self.pixelUnitSize.height, self.pixelUnitSize.width, self.pixelUnitSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];
            }
        }
        
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorSpace);
        free(data);
        
        [self.leftImageView.image drawAtPoint:NSMakePoint(0, self.rightImageView.image.size.height) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [newImage unlockFocus];
        [self setImage:newImage forImageView:self.leftImageView];
    }
}

@end
