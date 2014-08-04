# BKCameraController

A class to simplify the process of capturing photos and make testing in the simulator less of a hassle for photo-based apps.

## Installation

1. Add BKCameraController to your Podfile.
2. In your terminal, run `pod install`.

## Usage


1. Add `#import <BKCameraController/BKCameraController.h>` to your source file.
2. Initialize the camera controller: `_cameraController = [[BKCameraController alloc] initWithInitialPosition:AVCaptureDevicePositionBack autoFlashEnabled:YES];` (The default camera position is the front, and auto-flash is disabled by default)
3. Call `- (void)startCaptureSession` to start capturing and `- (void)stopCaptureSession` to stop capturing. One good place to do this is in `- (void)viewWillAppear:` and `- (void)viewDidDisppear:`, so the camera doesn't overheat from being left on.
4. Use the `session` property as necessary, i.e. for camera preview layers, and the other methods for camera position cycling, flash mode cycling, focus adjustment, and photo capture callbacks.
5. Add the following to set the camera controller's image response for testing in the simulator, revising the path as necessary: 
```objc
#if TARGET_IPHONE_SIMULATOR
    [BKCameraController setFakeImageData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///path-to/image.jpeg"]]];
#endif
```

## FAQ

**Q:** Why is this necessary?  
**A:** **You can use it in the simulator!** Testing in the simulator is insanely annoying when some functions simply aren't available. However, it's not always reasonable to expect the simulator to virtualize the response of low-level frameworks.

AVFoundation is a complex and very useful API, but every application that wants to customize its photo-taking experience needs to opt into this API, even when their needs are fairly straightforward. Because of this complexity, it's not hard to achieve an end result that works, but is subpar. For example, AVFoundation works best when it runs on a background queue, so that its blocking operations don't affect the main thread -- but not everyone does this.

This is an ideal problem to solve with an abstraction layer to serve those typical needs. In creating a standard component to interface with AVFoundation for the camera, we can also take on a little extra complexity and use a background queue properly on behalf of the consumers of BKCameraController's API.

*tl;dr:* __BKCameraController is usable in the simulator, and doesn't block the main (UI) thread.__

**Q:** My photos are rotated weirdly! What gives?
**A:** Well, the camera doesn't necessarily return the photo rotated with the direction "up" necessarily what you'd expect. It's not currently clear what the best approach to this is -- i.e. internally correct, offer a method in the public API to perform the transformation, or leave it to the developer -- but this snippet of code may prove useful for common use:

```objc
[_cameraController captureSampleWithCompletion:^(CIImage *image, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *photo;

        if (error) {
            NSLog(@"WARNING: Couldn't capture photo: %@", error);
            photo = nil;
        } else {
            CGFloat screenScale = [UIScreen mainScreen].scale;
            CGSize photoSizeInPixels = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));

            // Compute the scale from the source image to the output image, both measured in pixels
            size_t outputWidth = ceil(photoSizeInPixels.width);
            size_t outputHeight = ceil(photoSizeInPixels.height);

            // Swap the width and height since the source image is rotated
            size_t inputWidth = CGRectGetHeight(image.extent);
            size_t inputHeight = CGRectGetWidth(image.extent);

            CGFloat scale = fmax((CGFloat)outputWidth / inputWidth, (CGFloat)outputHeight / inputHeight);

            // Normalize the orientation
            CGAffineTransform transform;
            if (_videoPreview.connection.isVideoMirrored) {
                transform = CGAffineTransformMakeRotation(M_PI_2);

                transform = CGAffineTransformTranslate(transform, inputWidth, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
            } else {
                transform = CGAffineTransformMakeRotation(3 * M_PI_2);
            }

            // Scale the image
            transform = CGAffineTransformScale(transform, scale, scale);
            CIImage *transformedImage = [image imageByApplyingTransform:transform];

            // Crop the scaled image
            CGRect cropRect = CGRectCenterInRect(CGRectFromSize(photoSizeInPixels), [transformedImage extent]);
            CIImage *correctedImage = [transformedImage imageByCroppingToRect:cropRect];
            photo = [UIImage imageWithCIImage:correctedImage scale:screenScale orientation:UIImageOrientationUp];
        }

        // Do something with UIImage *photo here
    });
}];
```

Note that this code requires access to the `AVCaptureConnection` to determine whether or not to mirror the image.

**Q:** Why does direct capturing use `CIImage`? Why not `CMSampleBuffer` or `CVPixelBuffer`? Why not `CGImage`?  
**A:** The original interface *did* use `CMSampleBuffer`, but that's before simulator support was added. One of the goals is to be able to very cheaply transform the photo once taken, with as little loss of information as possible. Rendering to a `CGImage` only to have to re-import *that* into a `CIImage` is a wasted transformation.

While it seems theoretically possible to render a `CGImage` into a `CVPixelBuffer`, and in turn to a `CMSampleBuffer`, and to preserve the metadata dictionary -- and indeed this was the initial approach to adding simulator support --  `+[CIImage imageWithCVPixelBuffer:]` is either picky about its input format, or is simply non-functional in the iOS Simulator, and during development, only ever seemed to return `nil`. Additionally, there were many parameters to specify for the conversion to `CVPixelBuffer` and `CMSampleBuffer` which made assumptions about the image type (JPEG/PNG), color space, and color format -- assumptions that might not have held true for all example images.

Relegating `CMSampleBuffer` and `CVPixelBuffer` to implementation details of the `CIImage` presented to the user on devices allowed the simulator to take a much simpler path and simply use the more forgiving `+[CIImage imageWithData:` initializer.

*tl;dr:* __BKCameraController is fast and simple.__

**Q:** Support for video? Still Image brackets?  
**A:** Definitely possible, but also not something being actively worked on. Pull requests are very much welcome!

**Q:** This sucks!  
**Q:** It doesn't do X!  
**Q:** The way you structured your API sucks!  
**A:** This was built to make taking photos smooth. If you have a specific need, I'd be happy to incorporate that input into future revisions. If you have any suggestions or bug reports, please feel free to file an issue on GitHub. And if there's any concrete way to improve the API, I'd love to hear your input!

## Documentation

BKCameraController is fully documented. Check out the included docset!