// Copyright 2014-present 650 Industries. All rights reserved.

#import "BKCameraController+Simulator.h"

@import AssetsLibrary.ALAssetsLibrary;
@import CoreImage.CIImage;
@import ObjectiveC.runtime;
@import UIKit.UIDevice;

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
        CIImage *image = [CIImage imageWithData:[BKCameraController fakeImageData]];

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

@end
