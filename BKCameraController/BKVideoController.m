//
//  BKVideoController.m
//  BKCameraController
//
//  Created by Andrew Toulouse on 6/22/15.
//  Copyright © 2015 650 Industries, Inc. All rights reserved.
//

#import <BKCameraController/BKVideoController.h>
#import <BKCameraController/BKCameraController_Internal.h>

#import <AVFoundation/AVFoundation.h>
#import <libkern/OSAtomic.h>

@interface BKVideoController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong, readonly) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong, readonly) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic, copy) movie_capture_completion_t completion;

@end

@implementation BKVideoController

@dynamic delegate;

- (instancetype)initWithInitialPosition:(AVCaptureDevicePosition)position
                thumbnailCaptureEnabled:(BOOL)thumbnailCaptureEnabled
     subjectAreaChangeMonitoringEnabled:(BOOL)subjectAreaChangeMonitoringEnabled
{
    if (self = [super initWithInitialPosition:position
                             autoFlashEnabled:NO
           subjectAreaChangeMonitoringEnabled:subjectAreaChangeMonitoringEnabled
                                sessionPreset:AVCaptureSessionPresetHigh]) {
        self.stillsEnabled = thumbnailCaptureEnabled;
    }
    return self;
}

#pragma mark - Initialization

- (NSError *)initializeInputs
{
    NSError *error = [super initializeInputs];
    NSAssert(TARGET_IPHONE_SIMULATOR || error == nil, @"Error updating session with input");

    // TODO: test
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    [self.session beginConfiguration];

    if ([self.session canAddInput:audioDeviceInput]) {
        [self.session addInput:audioDeviceInput];
    }
    [self.session commitConfiguration];

    if (error) {
        NSString *message = [NSString stringWithFormat:@"Something went wrong when adding audio input \"%@\"", audioDeviceInput.device.localizedName];
        return [NSError errorWithDomain:@"com.github.basket.bkcameracontroller"
                                   code:0
                               userInfo:@{
                                          NSLocalizedDescriptionKey: message,
                                          NSUnderlyingErrorKey: error}];
    }
    return nil;
}

- (void)initializeOutputs
{
    [super initializeOutputs];

    _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self.session addOutput:_movieFileOutput];
}

#pragma mark - Capture

- (movie_stop_block_t)captureWithThumbnailBlock:(ciimage_capture_completion_t)thumbnailBlock completion:(movie_capture_completion_t)completion
{
    // If previous _recording value was 1, return
    // Else, _recording value is now 1; continue
    if (OSAtomicTestAndSet(0, &_recording)) {
        return ^{};
    }

    // Capture thumbnail if applicable
    if (self.stillsEnabled) {
        [self captureSampleWithCompletion:thumbnailBlock];
    }

    movie_capture_completion_t completionCopy = [completion copy];

    // Start capturing movie file
    dispatch_async(self.avQueue, ^{
        _completion = completionCopy;
        NSURL *outputUrl = [self _makeTemporaryMovieURL];

        [self.movieFileOutput startRecordingToOutputFileURL:outputUrl recordingDelegate:self];
    });

    return [^{
        dispatch_async(self.avQueue, ^{
            [self.movieFileOutput stopRecording];
        });
    } copy];
}

#pragma mark - Private

- (NSURL *)_makeTemporaryMovieURL
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    NSError *error;
    NSURL *cacheDir = [fileManager URLForDirectory:NSCachesDirectory
                                          inDomain:NSUserDomainMask
                                   appropriateForURL:nil
                                              create:YES
                                               error:&error];
    NSAssert(error == nil, @"Error: %@", error);
    NSString *filename = [NSString stringWithFormat:@"BKCameraController-temp-%@.mov", [NSUUID UUID].UUIDString];
    NSURL *outputUrl = [cacheDir URLByAppendingPathComponent:filename];
    return outputUrl;
}

#pragma mark - <AVCaptureFileOutputRecordingDelegate>

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(videoControllerDidStartRecording:)]) {
            [self.delegate videoControllerDidStartRecording:self];
        }
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    OSAtomicTestAndClear(0, &_recording);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completion) {
            self.completion(outputFileURL, error);
        }

        if ([self.delegate respondsToSelector:@selector(videoControllerDidStopRecording:)]) {
            [self.delegate videoControllerDidStopRecording:self];
        }
    });

    self.completion = nil;
}

@end
