/*******************************************************************************
 * Copyright (c) 2014, 2016  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

#ifdef __cplusplus
#import <opencv2/core/core.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#endif

#import "HLPLocation.h"
#import "HLPImageCaptureManager.h"
#import "HLPImageLocationManagerParameters.h"

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSUInteger, HLPLocationStatus) {
    HLPLocationStatusStable,
    HLPLocationStatusLocating,
    HLPLocationStatusLost,
    HLPLocationStatusBackground,
    HLPLocationStatusUnknown
};

@class HLPLocationManager;

@protocol HLPLocationManagerDelegate <CLLocationManagerDelegate>

@required
- (void)locationManager:(HLPLocationManager*)manager didLocationUpdate:(HLPLocation*)location;
- (void)locationManager:(HLPLocationManager*)manager didLocationStatusUpdate:(HLPLocationStatus)status;
- (void)locationManager:(HLPLocationManager*)manager didUpdateOrientation:(double)orientation withAccuracy:(double)accuracy;

@optional
- (void)locationManager:(HLPLocationManager*)manager didDebugInfoUpdate:(NSDictionary*)debugInfo;
- (void)locationManager:(HLPLocationManager*)manager didLogText:(NSString *)text;

@end

@interface HLPLocationManager: NSObject <CLLocationManagerDelegate, HLPImageCaptureDelegate>

@property (weak) id<HLPLocationManagerDelegate> delegate;

@property (readonly) CLLocationManager *clLocationManager;

@property (readonly) BOOL isSensorEnabled;
@property (readonly) BOOL isActive;
@property BOOL isBackground;
@property BOOL isAccelerationEnabled;
@property BOOL isStabilizeLocalizeEnabled;
@property BOOL isImageCnnEnabled;
@property (readonly) HLPLocationStatus currentStatus;
@property NSDictionary* parameters;


- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedManager;

- (void)setModelPath:(NSString*)modelPath;
- (void)setImageCnnSettings:(NSString*)settingsPath localizeMode:(HLPImageLocalizeMode)localizeMode useMobileNet:(BOOL)useMobileNet useLstm:(BOOL)useLstm;
- (void)start;
- (void)restart;
- (void)makeStatusUnknown;
- (void)resetLocation:(HLPLocation*)loc;
- (void)stop;
- (void)invalidate;

@end
