/*******************************************************************************
 * Copyright (c) 2018  IBM Corporation, Carnegie Mellon University and others
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

#import <bleloc/bleloc.h>
#import <bleloc/CnnManager.hpp>
#import "HLPLocationManagerCore.h"
#import <AVFoundation/AVFoundation.h>

@interface HLPImageLocalizationManager : NSObject {
    AVCaptureSession *session;
}

@property (readonly) BOOL isImageLocalizeRunning;
@property (readonly) BOOL isInitialized;

- (instancetype)init;
- (void)load:(NSString *)modelFile beaconSetFile:(NSString *)beaconSetFile imageLocalizeMode:(loc::ImageLocalizeMode)imageLocalizeMode floor:(NSNumber *)floor useMobileNet:(BOOL)useMobileNet useLstm:(BOOL)useLstm;
- (void)close;
- (int)floor;
- (void)putBeacons:(loc::Beacons)beacons;
- (NSArray *)runCnn:(cv::Mat&)image;

@end
