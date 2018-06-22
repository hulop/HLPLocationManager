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

#import "HLPImageCaptureManager.h"
#import <HLPLocationManager/HLPLocationManager.h>
#import <UIKit/UIKit.h>

@implementation HLPImageCaptureManager
{
    AVCaptureDeviceInput *input;
    AVCaptureVideoDataOutput *output;
    AVCaptureSession *session;
    AVCaptureDevice *camera;
    double _maxFPS;
    long lastCaptureTimestamp;
}

static HLPImageCaptureManager *instance;

+ (instancetype) sharedManager
{
    if (!instance) {
        instance = [[HLPImageCaptureManager alloc] initPrivate];
    }
    return instance;
}

- (instancetype) initPrivate
{
    self = [super init];
    
    _maxFPS = 1.0;
    lastCaptureTimestamp = 0;
    _lastAttitudePitchDegree = 0;
    
    return self;
}

- (void)startCapture:(double)maxFPS
{
    _maxFPS = maxFPS;
    if (session || camera) {
        [self stopCapture];
    }
    
    session = [[AVCaptureSession alloc] init];
    
    // set resolution
    //session.sessionPreset = AVCaptureSessionPresetHigh
    //session.sessionPreset = AVCaptureSessionPresetPhoto
    //session.sessionPreset = AVCaptureSessionPresetHigh
    //session.sessionPreset = AVCaptureSessionPresetMedium
    //session.sessionPreset = AVCaptureSessionPresetLow
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    camera = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                mediaType: AVMediaTypeVideo
                                                 position: AVCaptureDevicePositionBack];
    
    NSError *err = nil;
    input = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&err];
    if(!input || err) {
        NSLog(@"Error creating capture device input: %@", err.localizedDescription);
    } else if ([session canAddInput:input]) {
        [session addInput:input];
    }
    
    output = [[AVCaptureVideoDataOutput alloc] init];
    if([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    
    [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    output.alwaysDiscardsLateVideoFrames = true;
    
    // set full frame zoom
    if ([camera respondsToSelector:@selector(setVideoZoomFactor:)]) {
        if ([camera lockForConfiguration:nil]) {
            [camera setVideoZoomFactor:1.0];
            [camera unlockForConfiguration];
        }
    }
    
    // set automatic focus and exposure, restrict auto focus area far
    if ([camera lockForConfiguration:nil]) {
        camera.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        camera.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        camera.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionFar;
        
        [camera unlockForConfiguration];
    }
    
    // set max frame rate for the format whose width, height, are specified value, fov are larger than specified values
    int minWidth = 1280;
    int minHeight = 720;
    float minFov = 58.0;
    Float64 maxFrameRate = .0f;
    AVCaptureDeviceFormat *targetFormat = nil;
    NSArray *formats = camera.formats;
    for (AVCaptureDeviceFormat *format in formats) {
        AVFrameRateRange *frameRateRange = format.videoSupportedFrameRateRanges[0];
        Float64 frameRate = frameRateRange.maxFrameRate;
        
        CMFormatDescriptionRef desc = format.formatDescription;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
        int32_t width = dimensions.width;
        int32_t height = dimensions.height;
        float fov = format.videoFieldOfView;
        if (frameRate >= maxFrameRate && width >= minWidth && height >= minHeight && fov >= minFov) {
            targetFormat = format;
            maxFrameRate = frameRate;
        }
    }
    NSLog(@"record video format : %@", targetFormat);
    NSLog(@"record video max fps : %f", maxFrameRate);
    if (targetFormat && [camera lockForConfiguration:nil]) {
        camera.activeFormat = targetFormat;
        camera.activeVideoMaxFrameDuration = CMTimeMake(1, maxFrameRate);
        camera.activeVideoMinFrameDuration = CMTimeMake(1, maxFrameRate);
        [camera unlockForConfiguration];
    }
    
    // set video orientation from device orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
    for (AVCaptureConnection *connection in [output connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                connection.videoOrientation = videoOrientation;
            }
        }
    }
    
    // start video
    [session startRunning];
}

- (void)stopCapture
{
    if (session) {
        for(AVCaptureInput *input1 in session.inputs) {
            [session removeInput:input1];
        }
        for(AVCaptureOutput *output1 in session.outputs) {
            [session removeOutput:output1];
        }
        [session stopRunning];
    }
    session = nil;
    camera = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // wait specific interval
    long timestamp = [[NSDate date] timeIntervalSince1970]*1000;
    if (timestamp - lastCaptureTimestamp < 1000/_maxFPS) {
        return;
    }
    // check if camera is enabled
    HLPLocationManager* manager = [HLPLocationManager sharedManager];
    if (!manager.isActive || !manager.isSensorEnabled) {
        return;
    }
    
    UIImage *image = [self captureImage:sampleBuffer];
    self.lastCaptureImage = image;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [self.captureDelegate capture:timestamp image:image];
    });
    [self.imageViewDelegate showImage:timestamp image:image];
    lastCaptureTimestamp = timestamp;
}

- (UIImage *)captureImage:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGContextRef    cgContext;
    CGColorSpaceRef colorSpace;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(
                                      base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef  cgImage;
    UIImage*    image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                          orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return image;
}

@end
