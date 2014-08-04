// Copyright 2014-present 650 Industries. All rights reserved.

#import "BKCameraController.h"

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

@end
