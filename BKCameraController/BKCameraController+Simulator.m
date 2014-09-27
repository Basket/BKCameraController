// Copyright 2014-present 650 Industries. All rights reserved.

#import "BKCameraController+Simulator.h"

@import AssetsLibrary;
@import CoreImage;
@import ObjectiveC;
@import UIKit;

@interface BKCameraController ()
@property (nonatomic, strong) dispatch_queue_t avQueue;
@end

void __swizzled_captureAssetWithCompletion(BKCameraController *self, SEL _cmd, asset_capture_completion_t completion) {
    dispatch_async(self.avQueue, ^{
        NSData *data = [BKCameraController fakeImageData];
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(assetURL, nil);
                });
            }
        }];
    });
}

void __swizzled_captureSampleWithCompletion(BKCameraController *self, SEL _cmd, ciimage_capture_completion_t completion) {
    dispatch_async(((BKCameraController *)self).avQueue, ^{
        CIImage *image;
        if ([BKCameraController fakeImageData]) {
            image = [CIImage imageWithData:[BKCameraController fakeImageData]];
        } else {
            CIColor *fakeImageColor = [BKCameraController fakeImageColor];
            if (!fakeImageColor) {
                CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
                CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
                CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
                UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
                fakeImageColor = [CIColor colorWithCGColor:color.CGColor];
            }
            image = [CIImage imageWithColor:fakeImageColor];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image, nil);
        });
    });
}

@implementation BKCameraController (Simulator)

static IMP __original_captureAssetWithCompletion;
static IMP __original_captureSampleWithCompletion;
+ (void)load
{
    if ([[[UIDevice currentDevice].model lowercaseString] rangeOfString:@"simulator"].location != NSNotFound){
        Method assetMethod = class_getInstanceMethod([self class], @selector(captureAssetWithCompletion:));
        IMP assetImp = (IMP)__swizzled_captureAssetWithCompletion;
        __original_captureAssetWithCompletion = method_setImplementation(assetMethod, assetImp);

        Method sampleMethod = class_getInstanceMethod([self class], @selector(captureSampleWithCompletion:));
        IMP sampleImp = (IMP)__swizzled_captureSampleWithCompletion;
        __original_captureSampleWithCompletion = method_setImplementation(sampleMethod, sampleImp);
    }
}

static NSData *_fakeImageData;

+ (NSData *)fakeImageData
{
    return _fakeImageData;
}

+ (void)setFakeImageData:(NSData *)fakeImageData;
{
    _fakeImageData = fakeImageData;
}

static CIColor *_fakeImageColor;

+ (CIColor *)fakeImageColor
{
    return _fakeImageColor;
}

+ (void)setFakeImageColor:(CIColor *)fakeImageColor
{
    _fakeImageColor = fakeImageColor;
}

+ (void)setFakeImageColorFromUIColor:(UIColor *)fakeImageColor
{
    _fakeImageColor = [CIColor colorWithCGColor:fakeImageColor.CGColor];
}

@end
