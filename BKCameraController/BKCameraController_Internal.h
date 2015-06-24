//
//  BKCameraController_Internal.h
//  BKCameraController
//
//  Created by Andrew Toulouse on 6/23/15.
//  Copyright © 2015 650 Industries, Inc. All rights reserved.
//

#import <BKCameraController/BKCameraController.h>

@class AVCaptureDeviceInput;
@class AVCaptureStillImageOutput;

@interface BKCameraController ()

@property (nonatomic, assign, readwrite) AVAuthorizationStatus authorization;

@property (nonatomic, strong, readonly) dispatch_queue_t avQueue;

#pragma mark - State

@property (nonatomic, assign, readonly) BOOL sessionInitialized;
@property (nonatomic, assign, readonly) BOOL inputIsCycling;

#pragma mark - Features

@property (nonatomic, assign) BOOL stillsEnabled;
@property (nonatomic, assign) BOOL autoFlashEnabled;

#pragma mark - Inputs+Outputs

@property (nonatomic, strong, readonly) AVCaptureDeviceInput *activeDeviceInput;
@property (nonatomic, strong, readonly) AVCaptureStillImageOutput *stillImageOutput;

- (NSError *)initializeInputs;
- (void)initializeOutputs;

@end
