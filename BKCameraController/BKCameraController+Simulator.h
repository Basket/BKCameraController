// Copyright 2014-present 650 Industries. All rights reserved.

#import "BKCameraController.h"

@class CIColor;
@class UIColor;

@interface BKCameraController (Simulator)

/**
 Getter for the fake image data used by the simulator.
 
 @return The fake image data used by the simulator.
 */
+ (NSData *)fakeImageData;

/**
 Setter for the fake image data used by the simulator
 
 @param fakeImageData The fake image data to be used by the simulator.
 */
+ (void)setFakeImageData:(NSData *)fakeImageData;

/**
 Getter for the fake image color used by the simulator.

 @return The fake image color used by the simulator.
 */
+ (CIColor *)fakeImageColor;

/**
 Setter for the fake image  color used by the simulator

 @param fakeImageColor The fake image color to be used by the simulator.
 */
+ (void)setFakeImageColor:(NSData *)fakeImageColor;

/**
 Setter for fake image color from UIColor
 
 @param fakeImageColor UIColor
 */
+ (void)setFakeImageColorFromUIColor:(UIColor *)fakeImageColor;


@end
