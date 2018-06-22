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


#import "HLPLocationManager+Player.h"
#import "HLPImageCaptureManager.h"

#import <bleloc/BasicLocalizer.hpp>
#import <bleloc/LogUtil.hpp>

#include <iomanip>
#include <fstream>

using namespace std;
using namespace loc;

@interface HLPLocationManager () {
    BOOL _isSensorEnabled;
    BOOL isMapLoaded;
    BOOL _isAccelerationEnabled;
    NSOperationQueue *processQueue;
}

- (shared_ptr<BasicLocalizer>) localizer;
- (BOOL) valid;
- (BOOL) isMapLoaded;
- (NSDictionary*) anchor;
- (void) setCurrentFloor:(double) currentFloor_;
- (double) currentFloor;
- (double) currentOrientationAccuracy;
- (void) _processBeacons:(Beacons)beacons;
- (void) _stop;
@end

@implementation HLPLocationManager (Player)

static BOOL isPlaying;
static HLPLocation* replayResetRequestLocation;

- (void)stopLogReplay
{
    isPlaying = NO;
}

- (void)startLogReplay:(NSString *)path withOption:(NSDictionary*)option withLogHandler:(void (^)(NSString *line))handler
{
    _isSensorEnabled = NO;
    isPlaying = YES;
    
    self.localizer->resetStatus();
    
    [self _stop];
    
    dispatch_queue_t queue = dispatch_queue_create("org.hulop.logreplay", NULL);
    dispatch_async(queue, ^{
        [self _stop];
        [NSThread sleepForTimeInterval:1.0];
        [self start];
        
        while(!self.isActive || !self.valid || !self.isMapLoaded) {
            [NSThread sleepForTimeInterval:0.1];
        }
        
        std::ifstream ifs([path cStringUsingEncoding:NSUTF8StringEncoding]);
        std::string str;
        if (ifs.fail())
        {
            NSLog(@"Fail to load file");
            return;
        }
        long total = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
        long progress = 0;
        
        NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
        long first = 0;
        long timestamp = 0;
        
        BOOL bRealtime = [option[@"replay_in_realtime"] boolValue];
        BOOL bSensor = [option[@"replay_sensor"] boolValue];
        BOOL bShowSensorLog = [option[@"replay_show_sensor_log"] boolValue];
        BOOL bResetInLog = [option[@"replay_with_reset"] boolValue];
        
        NSMutableDictionary *marker = [@{} mutableCopy];
        long count = 0;
        while (getline(ifs, str) && isPlaying)
        {
            [NSThread sleepForTimeInterval:0.001];
            
            if (replayResetRequestLocation) {
                HLPLocation *loc = replayResetRequestLocation;
                double heading = loc.orientation;
                double acc = self.currentOrientationAccuracy;
                if (isnan(heading)) { // only location
                    heading = 0;
                } else { // set orientation
                    acc = 0;
                }
                
                heading = (heading - [self.anchor[@"rotate"] doubleValue])/180*M_PI;
                double x = sin(heading);
                double y = cos(heading);
                heading = atan2(y,x);
                
                loc::Location location;
                loc::GlobalState<Location> global(location);
                global.lat(loc.lat);
                global.lng(loc.lng);
                
                location = self.localizer->latLngConverter()->globalToLocal(global);
                
                loc::Pose newPose(location);
                if(isnan(loc.floor)){
                    newPose.floor(self.currentFloor);
                }else{
                    newPose.floor(round(loc.floor));
                }
                newPose.orientation(heading);
                
                loc::Pose stdevPose;
                stdevPose.x(1).y(1).orientation(acc/180*M_PI);
                self.localizer->resetStatus(newPose, stdevPose);
                
                replayResetRequestLocation = nil;
            }
            
            
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            
            long diffr = (now - start)*1000;
            long difft = timestamp - first;
            
            progress += str.length()+1;
            if (count*500 < difft) {
                
                auto currentLocationStatus = self.localizer->getStatus()->locationStatus();
                std::string locStatusStr = Status::locationStatusToString(currentLocationStatus);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:LOG_REPLAY_PROGRESS object:self userInfo:
                 @{
                   @"progress":@(progress),
                   @"total":@(total),
                   @"marker":marker,
                   @"floor":@(self.currentFloor),
                   @"difft":@(difft),
                   @"message":@(locStatusStr.c_str())
                   }];
                count++;
            }
            
            if (difft - diffr > 1000 && bRealtime) { // skip
                first +=  difft - diffr - 1000;
                difft = diffr + 1000;
            }
            
            while (difft-diffr > 0 && bRealtime && isPlaying) {
                //std::cout << difft-diffr << std::endl;
                [NSThread sleepForTimeInterval:0.1];
                diffr = ([[NSDate date] timeIntervalSince1970] - start)*1000;
            }
            //std::cout << str << std::endl;
            try {
                std::vector<std::string> v;
                boost::split(v, str, boost::is_any_of(" "));
                
                if (bSensor && v.size() > 3) {
                    std::string logString = v.at(3);
                    // Parsing beacons value
                    if (logString.compare(0, 6, "Beacon") == 0) {
                        Beacons beacons = DataUtils::parseLogBeaconsCSV(logString);
                        std::cout << "LogReplay:" << beacons.timestamp() << ",Beacon," << beacons.size();
                        for(auto& b : beacons){
                            if(b.rssi()==0.0){
                                b.rssi(-100);
                            }
                            std::cout << "," << b.major() << "," << b.minor() << "," << b.rssi();
                        }
                        std::cout << std::endl;
                        timestamp = beacons.timestamp();
                        [self _processBeacons:beacons];
                    }
                    // Parsing acceleration values
                    else if (logString.compare(0, 3, "Acc") == 0) {
                        Acceleration acc = LogUtil::toAcceleration(logString);
                        if (bShowSensorLog) {
                            std::cout << "LogReplay:" << acc.timestamp() << ",Acc," << acc << std::endl;
                        }
                        timestamp = acc.timestamp();
                        if (self.isAccelerationEnabled) {
                            self.localizer->disableAcceleration(false, timestamp);
                        } else {
                            self.localizer->disableAcceleration(true, timestamp);
                        }
                        self.localizer->putAcceleration(acc);
                    }
                    // Parsing motion values
                    else if (logString.compare(0, 6, "Motion") == 0) {
                        Attitude att = LogUtil::toAttitude(logString);
                        if (bShowSensorLog) {
                            std::cout << "LogReplay:" << att.timestamp() << ",Motion," << att << std::endl;
                        }
                        timestamp = att.timestamp();
                        self.localizer->putAttitude(att);
                        
                        // for image localization
                        [HLPImageCaptureManager sharedManager].lastAttitudePitchDegree = att.pitch() * 180 / M_PI;
                    }
                    else if (logString.compare(0, 7, "Heading") == 0){
                        Heading head = LogUtil::toHeading(logString);
                        self.localizer->putHeading(head);
                        if (bShowSensorLog) {
                            std::cout << "LogReplay:" << head.timestamp() << ",Heading," << head.trueHeading() << "," << head.magneticHeading() << "," << head.headingAccuracy() << std::endl;
                        }
                    }
                    else if (logString.compare(0, 9, "Altimeter") == 0){
                        Altimeter alt = LogUtil::toAltimeter(logString);
                        self.localizer->putAltimeter(alt);
                        if (bShowSensorLog) {
                            std::cout << "LogReplay:" << alt.timestamp() << ",Altimeter," << alt.relativeAltitude() << "," << alt.pressure() << std::endl;
                        }
                    }
                    else if (logString.compare(0, 19, "DisableAcceleration") == 0){
                        std::vector<std::string> values;
                        boost::split(values, logString, boost::is_any_of(","));
                        int da = stoi(values.at(1));
                        long timestamp = stol(values.back());
                        if(da==1){
                            _isAccelerationEnabled = NO; // disable
                            self.localizer->disableAcceleration(true, timestamp);
                        }else{
                            _isAccelerationEnabled = YES; // enable
                            self.localizer->disableAcceleration(false, timestamp);
                        }
                        if (bShowSensorLog) {
                            std::cout << "LogReplay:" << logString << std::endl;
                        }
                    }
                    // Parsing image values
                    else if (logString.compare(0, 5, "Image") == 0) {
                        long timestamp = LogUtil::toImage(logString);
                        
                        NSString *docDir = [path stringByDeletingLastPathComponent];
                        NSString *logDirName = [[path lastPathComponent] stringByDeletingPathExtension];
                        NSString *logDirPath = [docDir stringByAppendingPathComponent:logDirName];
                        NSString *imageFileName = [NSString stringWithFormat:@"%ld.jpg", timestamp];
                        NSString *imageFilePath = [logDirPath stringByAppendingPathComponent:imageFileName];
                        UIImage *imageData = [UIImage imageWithContentsOfFile:imageFilePath];
                        
                        [HLPImageCaptureManager sharedManager].lastCaptureImage = imageData;
                        [[HLPLocationManager sharedManager] capture:timestamp image:imageData];
                        [[HLPImageCaptureManager sharedManager].imageViewDelegate showImage:timestamp image:imageData];
                        
                        if (bShowSensorLog) {
                            std::cout << "LogReplay:" << timestamp << ",Image," << imageFilePath << std::endl;
                        }
                    }
                    // Parsing reset
                    else if (logString.compare(0, 5, "Reset") == 0) {
                        if (bResetInLog){
                            // "Reset",lat,lng,floor,heading,timestamp
                            std::vector<std::string> values;
                            boost::split(values, logString, boost::is_any_of(","));
                            timestamp = stol(values.at(5));
                            double lat = stod(values.at(1));
                            double lng = stod(values.at(2));
                            double floor = stod(values.at(3));
                            double orientation = stod(values.at(4));
                            std::cout << "LogReplay:" << timestamp << ",Reset,";
                            std::cout << std::setprecision(10) << lat <<"," <<lng;
                            std::cout <<"," <<floor <<"," <<orientation << std::endl;
                            marker[@"lat"] = @(lat);
                            marker[@"lng"] = @(lng);
                            marker[@"floor"] = @(floor);
                            
                            HLPLocation *loc = [[HLPLocation alloc] initWithLat:lat Lng:lng Floor:floor];
                            [loc updateOrientation:orientation withAccuracy:0];
                            
                            replayResetRequestLocation = loc;
                        }
                    }
                    // Marker
                    else if (logString.compare(0, 6, "Marker") == 0){
                        // "Marker",lat,lng,floor,timestamp
                        std::vector<std::string> values;
                        boost::split(values, logString, boost::is_any_of(","));
                        double lat = stod(values.at(1));
                        double lng = stod(values.at(2));
                        double floor = stod(values.at(3));
                        timestamp = stol(values.at(4));
                        std::cout << "LogReplay:" << timestamp << ",Marker,";
                        std::cout << std::setprecision(10) << lat << "," << lng;
                        std::cout << "," << floor << std::endl;
                        marker[@"lat"] = @(lat);
                        marker[@"lng"] = @(lng);
                        marker[@"floor"] = @(floor);
                    }
                }
                
                if (!bSensor) {
                    if (v.size() > 3 && v.at(3).compare(0, 4, "Pose") == 0) {
                        std::string log_string = v.at(3);
                        std::vector<std::string> att_values;
                        boost::split(att_values, log_string, boost::is_any_of(","));
                        timestamp = stol(att_values.at(7));
                        
                        double lat = stod(att_values.at(1));
                        double lng = stod(att_values.at(2));
                        double floor = stod(att_values.at(3));
                        self.currentFloor = floor;
                        double accuracy = stod(att_values.at(4));
                        double orientation = stod(att_values.at(5));
                        double orientationAccuracy = stod(att_values.at(6));
                        
                        [self.delegate locationManager:self didLocationUpdate:[[HLPLocation alloc] initWithLat:lat Lng:lng Accuracy:accuracy Floor:floor Speed:0 Orientation:orientation OrientationAccuracy:orientationAccuracy]];
                    }
                }
                
                if (handler) {
                    NSString *objcStr = [[NSString alloc] initWithCString:str.c_str() encoding:NSUTF8StringEncoding];
                    handler(objcStr);
                }
                
                if (first == 0) {
                    first = timestamp;
                }
                
            } catch (std::invalid_argument e){
                std::cerr << e.what() << std::endl;
                std::cerr << "error in parse log file" << std::endl;
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:LOG_REPLAY_PROGRESS object:self userInfo:@{@"progress":@(total),@"total":@(total)}];
        isPlaying = NO;
        _isSensorEnabled = YES;

        [self _stop];
        [self start];
        while(!self.isActive || !self.valid || !self.isMapLoaded) {
            [NSThread sleepForTimeInterval:0.1];
        }
    });
}

@end
