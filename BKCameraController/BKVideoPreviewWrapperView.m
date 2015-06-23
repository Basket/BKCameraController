// Copyright 2014-present Andrew Toulouse.
// Copyright 2014-present 650 Industries.
// Distributed under the MIT License: http://opensource.org/licenses/MIT

#import <BKCameraController/BKVideoPreviewWrapperView.h>

#import <AVFoundation/AVFoundation.h>

#define __layer ((AVCaptureVideoPreviewLayer *)self.layer)

@implementation BKVideoPreviewWrapperView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (void)setSession:(AVCaptureSession *)session
{
    __layer.session = session;
}

- (AVCaptureSession *)session
{
    return __layer.session;
}

- (AVCaptureConnection *)connection
{
    return __layer.connection;
}

- (void)setVideoGravity:(NSString *)videoGravity
{
    __layer.videoGravity = [videoGravity copy];
}

- (NSString *)videoGravity
{
    return __layer.videoGravity;
}

- (CGPoint)captureDevicePointOfInterestForPoint:(CGPoint)point
{
    return [__layer captureDevicePointOfInterestForPoint:point];
}

@end
