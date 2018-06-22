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

#import "HLPImageLocalizationManager.h"
#import <bleloc/CnnManager.hpp>
#import <bleloc/CnnFileUtil.hpp>
#import <UIKit/UIKit.h>

// These dimensions need to match those the model was trained with.
const int wanted_input_width = 224;
const int wanted_input_height = 224;
const int wanted_input_channels = 3;

const float input_mean = 128.0f;
const float input_std = 1.0f;
const float input_beacon_mean = 0.0f;
const float input_beacon_std = 1.0f;

@interface HLPImageLocalizationManager()

@end

@implementation HLPImageLocalizationManager
{
    BOOL _isImageLocalizeRunning;
    BOOL _useMobileNet;
    BOOL _useLstm;
    NSNumber *_floor;
    std::map<std::pair<int,int>,int> beaconid_index_map;
    std::vector<float> beacon_rssis;
    std::shared_ptr<loc::CnnManager> cnnManager;
}

- (instancetype)init {
    self = [super init];
    
    cnnManager = std::shared_ptr<loc::CnnManager>(new loc::CnnManager());
    
    _floor = [NSNumber numberWithInt:-1];
    
    _isImageLocalizeRunning = NO;
    
    return self;
}

- (void)load:(NSString *)modelFile beaconSetFile:(NSString *)beaconSetFile imageLocalizeMode:(loc::ImageLocalizeMode)imageLocalizeMode floor:(NSNumber *)floor useMobileNet:(BOOL)useMobileNet useLstm:(BOOL)useLstm {
    cnnManager->init([modelFile UTF8String], imageLocalizeMode);
    
    beaconid_index_map = loc::CnnFileUtil::parseBeaconSettingFile([beaconSetFile UTF8String]);
    beacon_rssis.resize(beaconid_index_map.size(), 0);
    
    _floor = floor;
    
    _useMobileNet = useMobileNet;
    _useLstm = useLstm;
}

- (void)close {
    cnnManager->close();
    
    beaconid_index_map.clear();
    beacon_rssis.clear();
    
    _floor = [NSNumber numberWithInt:-1];
}

- (BOOL)isInitialized {
    if (cnnManager->isInitialized()) {
        return YES;
    } else {
        return NO;
    }
}

- (int)floor {
    return [_floor intValue];
}

- (void)putBeacons:(loc::Beacons)beacons {
    beacon_rssis.resize(beaconid_index_map.size(), 0);
    for (int i=0; i<beacons.size(); i++) {
        loc::Beacon beacon = beacons[i];
        long rssi = -100;
        if (beacon.rssi() < 0) {
            rssi = beacon.rssi();
        }
        int major = beacon.major();
        int minor = beacon.minor();
        NSLog(@"major=%d, minor=%d, rssi=%ld", minor, major, rssi);
        if (beaconid_index_map.find(std::make_pair(major,minor))!=beaconid_index_map.end()) {
            int beaconIndex = beaconid_index_map[std::make_pair(major,minor)];
            float norm_rssi = rssi + 100;
            beacon_rssis[beaconIndex] = (norm_rssi-input_beacon_mean)/input_beacon_std;
        }
    }
}

- (NSArray *)runCnn:(cv::Mat&)image {
    assert(image.cols==wanted_input_width && image.rows==wanted_input_height);
    assert(beaconid_index_map.size()==beacon_rssis.size());
    
    _isImageLocalizeRunning = YES;
    
    const int image_channels = 4;
    
    assert(image_channels >= wanted_input_channels);
    tensorflow::Tensor image_tensor;
    float *out;
    if (!_useLstm) {
        image_tensor = tensorflow::Tensor(tensorflow::DT_FLOAT,
                                          tensorflow::TensorShape({1, wanted_input_height, wanted_input_width, wanted_input_channels}));
        auto image_tensor_mapped = image_tensor.tensor<float, 4>();
        out = image_tensor_mapped.data();
    } else {
        image_tensor = tensorflow::Tensor(tensorflow::DT_FLOAT,
                                          tensorflow::TensorShape({1, 1, wanted_input_height, wanted_input_width, wanted_input_channels}));
        auto image_tensor_mapped = image_tensor.tensor<float, 5>();
        out = image_tensor_mapped.data();
    }
    for (int y = 0; y < wanted_input_height; ++y) {
        float *out_row = out + (y * wanted_input_width * wanted_input_channels);
        for (int x = 0; x < wanted_input_width; ++x) {
            cv::Vec3b in_pixel = image.at<cv::Vec3b>(y, x);
            float *out_pixel = out_row + (x * wanted_input_channels);
            for (int c = 0; c < wanted_input_channels; ++c) {
                out_pixel[c] = (in_pixel[c] - input_mean) / input_std;
            }
        }
    }
    
    tensorflow::Tensor beacon_tensor;
    float *beacon_out;
    if (!_useLstm) {
        beacon_tensor = tensorflow::Tensor(tensorflow::DT_FLOAT,
                                           tensorflow::TensorShape({1, static_cast<long long>(beaconid_index_map.size()), 1, 1}));
        auto beacon_tensor_mapped = beacon_tensor.tensor<float, 4>();
        beacon_out = beacon_tensor_mapped.data();
    } else {
        beacon_tensor = tensorflow::Tensor(tensorflow::DT_FLOAT,
                                           tensorflow::TensorShape({1, 1, static_cast<long long>(beaconid_index_map.size()), 1, 1}));
        auto beacon_tensor_mapped = beacon_tensor.tensor<float, 5>();
        beacon_out = beacon_tensor_mapped.data();
    }
    for (int i = 0; i < beaconid_index_map.size(); i++) {
        beacon_out[i] = beacon_rssis[i];
    }
    
    std::vector<double> result = cnnManager->runCnn(image_tensor, beacon_tensor, _useMobileNet, _useLstm);
    
    _isImageLocalizeRunning = NO;
    
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (int i=0; i<result.size(); i++) {
        NSNumber *valueObject = [NSNumber numberWithFloat:result[i]];
        [resultArray addObject:valueObject];
    }
    return resultArray;
}

@end
