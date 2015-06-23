//
//  BKVideoController.h
//  BKCameraController
//
//  Created by Andrew Toulouse on 6/22/15.
//  Copyright © 2015 650 Industries, Inc. All rights reserved.
//

#import <BKCameraController/BKCameraController.h>

@class BKVideoController;

/** Completion callback invoked upon movie capture. */
typedef void (^movie_capture_completion_t)(NSURL *outputUrl, NSError *error);

@protocol BKVideoControllerDelegate <BKCameraControllerDelegate>

- (void)videoControllerDidStartRecording:(BKVideoController *)videoController;
- (void)videoControllerDidStopRecording:(BKVideoController *)videoController;

@end

@interface BKVideoController : BKCameraController

/**
 The receiver's delegate or nil if it doesn’t have a delegate.

 @discussion For a list of methods your delegate object can implement, see [BKVideoControllerDelegate Protocol Reference](BKVideoControllerDelegate)
 */
@property (nonatomic, weak) id<BKVideoControllerDelegate> delegate;

@property (nonatomic, assign, readonly, getter = isRecording) BOOL recording;

- (instancetype)initWithInitialPosition:(AVCaptureDevicePosition)position
                thumbnailCaptureEnabled:(BOOL)thumbnailCaptureEnabled
     subjectAreaChangeMonitoringEnabled:(BOOL)subjectAreaChangeMonitoringEnabled;

- (void)captureWithThumbnailBlock:(ciimage_capture_completion_t)thumbnailBlock completion:(movie_capture_completion_t)completion;

@end
