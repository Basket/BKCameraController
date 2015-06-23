// Copyright 2014-present Andrew Toulouse.
// Copyright 2014-present 650 Industries.
// Distributed under the MIT License: http://opensource.org/licenses/MIT

#import <UIKit/UIKit.h>

@class AVCaptureConnection;
@class AVCaptureSession;

@interface BKVideoPreviewWrapperView : UIView

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong, readonly) AVCaptureConnection *connection;
@property (nonatomic, copy) NSString *videoGravity;

- (CGPoint)captureDevicePointOfInterestForPoint:(CGPoint)point;

@end
