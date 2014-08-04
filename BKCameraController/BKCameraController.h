// Copyright 2014-present 650 Industries. All rights reserved.

@import AVFoundation.AVCaptureDevice;
@import AVFoundation.AVCaptureSession;

@class CIImage;
@protocol BKCameraControllerDelegate;

/** Completion callback invoked upon <CIImage> capture. */
typedef void (^ciimage_capture_completion_t)(CIImage *image, NSError *error);

/** Completion callback invoked upon asset capture. */
typedef void (^asset_capture_completion_t)(NSURL *assetURL, NSError *error);

/**
 A wrapper for AVCaptureSession to simplify the process of capturing photos.
 */
@interface BKCameraController : NSObject

/**
 The receiver’s delegate or nil if it doesn’t have a delegate.
 
 @discussion For a list of methods your delegate object can implement, see [BKCameraControllerDelegate Protocol Reference](BKCameraControllerDelegate)
 */
@property (nonatomic, weak) id<BKCameraControllerDelegate> delegate;

/** The controller-owned `AVCaptureSession` instance. */
@property (nonatomic, strong, readonly) AVCaptureSession *session;
/** The current camera position. */
@property (nonatomic, assign, readonly) AVCaptureDevicePosition position;
/** The current camera flash mode. */
@property (nonatomic, assign, readonly) AVCaptureFlashMode flashMode;
/** Whether the current camera has the capability to flash. */
@property (nonatomic, assign, readonly) BOOL flashCapable;

/** @name Initializing a BKCameraController object  */

/**
 Initializes the camera controller using the specified starting parameters.
 
 @param position The position used to select the initial capture device used by the camera controller. Defaults to `AVCaptureDevicePositionBack`.
 @param enabled YES if the camera controller should include `AVCaptureFlashModeAuto` when cycling the flash mode. Defaults to `NO`.
 @return An initialized `BKCameraController` instance.
 */
- (instancetype)initWithInitialPosition:(AVCaptureDevicePosition)position
                       autoFlashEnabled:(BOOL)enabled __attribute__((objc_designated_initializer));

/** @name Starting/Stopping Capture Session State  */

/**
 Tells the receiver to start the capture session.
 
 @discussion This method is used to start the receiver's capture session. This method is asynchronous and runs on a serial background queue owned by the receiver.
 */
- (void)startCaptureSession;

/**
 Tells the receiver to stop the capture session.

 @discussion This method is used to stop the receiver's capture session. This method is asynchronous and runs on a serial background queue owned by the receiver.
 */
- (void)stopCaptureSession;

/** @name Adjusting Camera Settings  */

/**
 Sets the focus and exposure point to the specified point, if supported.
 
 @param point The point to set the exposure and focus.
 */
- (void)autoAdjustCameraToPoint:(CGPoint)point;

/**
 Cycles through supported flash modes. Skips `AVCaptureFlashModeAuto` if the receiver was initialized with `autoFlashEnabled` set to `NO`.
 */
- (void)cycleFlashMode;

/**
 Cycles through supported flash modes. If no flash mode at all is supported (such as on the front-facing camera), <flashCapable> is set to `NO`, otherwise `YES`.
 */
- (void)cyclePosition;

/** @name Capturing Photos  */

/**
 Capture a photo and save it, along with its EXIF metadata, to the camera roll.

 @param completion A completion block supplying either a valid Asset <NSURL> or a <NSError>. Executed on the main thread.

 - *assetURL* The Asset URL to the captured media. nil if an error occurred.
 - *error* The error, if a problem occurred during capture.
 */
- (void)captureAssetWithCompletion:(asset_capture_completion_t)completion;

/**
 Capture a photo.

 @param completion A completion block supplying either a <CIImage> or a <NSError>. Executed on the main thread.

 - *image* A CIImage wrapping the sample buffer's pixel buffer, captured by the camera. nil if an error occurred.
 - *error* The error, if a problem occurred during capture.
 */
- (void)captureSampleWithCompletion:(ciimage_capture_completion_t)completion;
@end

/**
 The delegate of a <BKCameraController> object must adopt the <BKCameraControllerDelegate> protocol.
 */
@protocol BKCameraControllerDelegate <NSObject>

@optional

/**
 Tells the delegate that the camera controller will cycle the camera position.
 
 @param cameraController The camera controller object informing the delegate of this event.
 */
- (void)cameraControllerWillCyclePosition:(BKCameraController *)cameraController;

/**
 Tells the delegate that the camera controller cycled the camera position.

 @param cameraController The camera controller that cycled position.
 */
- (void)cameraControllerDidCyclePosition:(BKCameraController *)cameraController;

@end

#if TARGET_IPHONE_SIMULATOR
#import "BKCameraController+Simulator.h"
#endif
