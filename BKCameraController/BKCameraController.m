// Copyright 2014-present 650 Industries. All rights reserved.

#import "BKCameraController.h"

@import AssetsLibrary.ALAssetsLibrary;
@import AVFoundation.AVCaptureInput;
@import AVFoundation.AVCaptureOutput;
@import AVFoundation.AVMediaFormat;
@import AVFoundation.AVVideoSettings;
@import CoreImage.CIImage;
@import ImageIO.CGImageProperties;

@interface BKCameraController ()
@property (nonatomic, strong) dispatch_queue_t avQueue;
@end

@implementation BKCameraController {
    BOOL _autoFlashEnabled;

    BOOL _sessionInitialized;
    BOOL _inputIsCycling;

    AVCaptureDeviceInput *_activeDeviceInput;
    AVCaptureStillImageOutput *_stillImageOutput;

    AVCaptureFlashMode _avFlashMode; // avQueue-affined flash mode
    AVCaptureDevicePosition _avPosition; // avQueue-affined device position
}

- (instancetype)initWithInitialPosition:(AVCaptureDevicePosition)position
                       autoFlashEnabled:(BOOL)enabled
{
    if (self = [super init]) {
        _autoFlashEnabled = enabled;

        _avQueue = dispatch_queue_create("net.sixfivezero.av", DISPATCH_QUEUE_SERIAL);

        _position = position;
        _session = [[AVCaptureSession alloc] init];
    }
    return self;
}

- (instancetype)init
{
    if (self = [self initWithInitialPosition:AVCaptureDevicePositionBack autoFlashEnabled:NO]) {
    }
    return self;
}

- (void)_initialSessionSetup
{
    NSAssert(![NSThread isMainThread], @"Method should not be run on the main thread");
    NSAssert(!_sessionInitialized, @"Session already initialized!");

    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _session.sessionPreset = AVCaptureSessionPresetHigh;
    }

    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [_session addOutput:_stillImageOutput];

    NSError *error = nil;
    AVCaptureDevice *initialDevice = [self _captureDeviceForPosition:_position];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:initialDevice error:&error];
    NSAssert(TARGET_IPHONE_SIMULATOR || error == nil, @"Error getting device input");

    [self _updateSessionWithInput:input error:&error];
    NSAssert(TARGET_IPHONE_SIMULATOR || error == nil, @"Error updating session with input");

    _sessionInitialized = YES;
}

- (void)startCaptureSession
{
    dispatch_async(_avQueue, ^{
        if (!_sessionInitialized) {
            [self _initialSessionSetup];
        }
        [_session startRunning];
    });
}

- (void)stopCaptureSession
{
    dispatch_async(_avQueue, ^{
        [_session stopRunning];
    });
}

#pragma mark - Camera control

- (AVCaptureDevice *)_captureDeviceForPosition:(AVCaptureDevicePosition)position
{
    NSAssert(![NSThread isMainThread], @"Method should not be run on the main thread");
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (BOOL)_updateSessionWithInput:(AVCaptureDeviceInput *)newInput error:(NSError * __autoreleasing *)error
{
    NSAssert(![NSThread isMainThread], @"Method should not be run on the main thread");
    [_session beginConfiguration];
    if (_activeDeviceInput) {
        [_session removeInput:_activeDeviceInput];
    }

    if (![_session canAddInput:newInput]) {
        // Roll back the changes
        if (_activeDeviceInput) {
            [_session addInput:_activeDeviceInput];
        }
        [_session commitConfiguration];
        NSString *message = [NSString stringWithFormat:@"Something went wrong when switching to the %@", newInput.device.localizedName];
        if (error) {
            *error = [NSError errorWithDomain:@"net.sixfivezero" code:0 userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return YES;
    }

    [_session addInput:newInput];
    _activeDeviceInput = newInput;
    [_session commitConfiguration];
    return NO;
}

- (void)autoAdjustCameraToPoint:(CGPoint)point
{
    dispatch_async(_avQueue, ^{
        NSError *error = nil;
        AVCaptureDevice *camera = [_activeDeviceInput device];
        [camera lockForConfiguration:&error];
        if (error) {
            NSLog(@"ERROR: problem adjusting camera: %@", error);
            // TODO: handle error
            return;
        }
        if (camera.isFocusPointOfInterestSupported) {
            camera.focusPointOfInterest = point;
        }
        if (camera.isExposurePointOfInterestSupported) {
            camera.exposurePointOfInterest = point;
        }
        if ([camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            camera.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        if ([camera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            camera.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        if ([camera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            camera.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
        [camera unlockForConfiguration];
    });
}

- (void)cycleFlashMode
{
    dispatch_async(_avQueue, ^{
        AVCaptureDevice *camera = _activeDeviceInput.device;
        AVCaptureFlashMode currentFlashMode = camera.flashMode;
        AVCaptureFlashMode nextFlashMode = AVCaptureFlashModeOff;

        switch (currentFlashMode) {
            case AVCaptureFlashModeOff:
                if ([camera isFlashModeSupported:AVCaptureFlashModeOn]) {
                    nextFlashMode = AVCaptureFlashModeOn;
                }
                break;
            case AVCaptureFlashModeOn:
                if ([camera isFlashModeSupported:AVCaptureFlashModeAuto] && _autoFlashEnabled) {
                    nextFlashMode = AVCaptureFlashModeAuto;
                } else {
                    nextFlashMode = AVCaptureFlashModeOff;
                }
                break;
            case AVCaptureFlashModeAuto:
                nextFlashMode = AVCaptureFlashModeOff;
                break;
            default:
                nextFlashMode = AVCaptureFlashModeOff;
                NSAssert(NO, @"Unknown flash mode: %d", (int)currentFlashMode);
        }

        // The front camera doesn't even support _setting_ flashMode, even to off.
        BOOL flashCapable = YES;
        if (![camera isFlashModeSupported:nextFlashMode]) {
            flashCapable = NO;
        }

        // Optimistically update button
        dispatch_async(dispatch_get_main_queue(), ^{
            [self willChangeValueForKey:@"flashCapable"];
            _flashCapable = flashCapable;
            [self didChangeValueForKey:@"flashCapable"];
            [self willChangeValueForKey:@"flashMode"];
            _flashMode = nextFlashMode;
            [self didChangeValueForKey:@"flashMode"];
        });

        // Don't bother trying to change flash mode if not capable
        if (!flashCapable) {
            return;
        }

        NSError *error = nil;
        [camera lockForConfiguration:&error];
        if (error) {
            NSLog(@"error cycling flash: %@", error);
            // Roll back icon change
            dispatch_async(dispatch_get_main_queue(), ^{
                [self willChangeValueForKey:@"flashCapable"];
                _flashCapable = flashCapable;
                [self didChangeValueForKey:@"flashCapable"];
                [self willChangeValueForKey:@"flashMode"];
                _flashMode = nextFlashMode;
                [self didChangeValueForKey:@"flashMode"];
            });
            return;
        }

        camera.flashMode = nextFlashMode;
        [camera unlockForConfiguration];
    });
}

- (void)cyclePosition
{
    if (_inputIsCycling) {
        return;
    }

    _inputIsCycling = YES;

    if ([_delegate respondsToSelector:@selector(cameraControllerWillCyclePosition:)]) {
        [_delegate cameraControllerWillCyclePosition:self];
    }

    dispatch_async(_avQueue, ^{
        AVCaptureDevice *camera = _activeDeviceInput.device;
        AVCaptureDevicePosition currentPosition = camera.position;
        AVCaptureDevicePosition nextPosition = AVCaptureDevicePositionUnspecified;

        switch (currentPosition) {
            case AVCaptureDevicePositionBack:
                nextPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                nextPosition = AVCaptureDevicePositionBack;
                break;
            default:
                nextPosition = AVCaptureDevicePositionUnspecified;
                NSAssert(NO, @"Unknown position: %d", (int)currentPosition);
        }

        NSError *error = nil;
        AVCaptureDevice *newCamera = [self _captureDeviceForPosition:nextPosition];
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:&error];
        if (error) {
            NSLog(@"ERROR: problem cycling position: %@", error);
            return;
        }
        [self _updateSessionWithInput:newInput error:&error];
        if (error) {
            NSLog(@"ERROR: problem cycling position: %@", error);
            return;
        }

        AVCaptureFlashMode newFlashMode = newCamera.flashMode;
        BOOL flashCapable = YES;
        if (![newCamera isFlashModeSupported:newFlashMode]) {
            flashCapable = NO;
        }

        _avFlashMode = newFlashMode;
        _avPosition = nextPosition;

        dispatch_async(dispatch_get_main_queue(), ^{
            _inputIsCycling = NO;
            [self willChangeValueForKey:@"flashCapable"];
            _flashCapable = flashCapable;
            [self didChangeValueForKey:@"flashCapable"];
            [self willChangeValueForKey:@"flashMode"];
            _flashMode = newFlashMode;
            [self didChangeValueForKey:@"flashMode"];
            [self willChangeValueForKey:@"position"];
            _position = nextPosition;
            [self didChangeValueForKey:@"position"];

            if ([_delegate respondsToSelector:@selector(cameraControllerDidCyclePosition:)]) {
                [_delegate cameraControllerDidCyclePosition:self];
            }
        });
    });
}

#pragma mark - Photo capture

- (void)captureAssetWithCompletion:(asset_capture_completion_t)completion
{
    dispatch_async(_avQueue, ^{
        AVCaptureConnection *connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        _stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
        [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection
                                                       completionHandler:
         ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
             if (error) {
                 NSLog(@"ERROR: problem capturing photo: %@", [error localizedDescription]);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     completion(nil, error);
                 });
                 return;
             }

             CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
             NSDictionary *exif;
             if (exifAttachments) {
                 exif = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)(exifAttachments)];
             } else {
                 exif = nil;
             }

             NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
             [assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:exif completionBlock:^(NSURL *assetURL, NSError *error) {
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
         }];
    });
}

- (void)captureSampleWithCompletion:(ciimage_capture_completion_t)completion
{
    dispatch_async(_avQueue, ^{
        AVCaptureConnection *connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        _stillImageOutput.outputSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
        [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection
                                                       completionHandler:
         ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
             if (error) {
                 NSLog(@"ERROR: problem capturing photo: %@", [error localizedDescription]);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     completion(nil, error);
                 });
                 return;
             }

             CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageSampleBuffer);
             NSDictionary *attachments = (__bridge_transfer NSDictionary *)CMCopyDictionaryOfAttachments(NULL, imageSampleBuffer, kCMAttachmentMode_ShouldPropagate);
             CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer options:@{kCIImageProperties: attachments}];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(image, nil);
             });
         }];
    });
}

@end
