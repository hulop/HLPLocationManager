# HLPLocationManager

## BLE beacon-based localization Framework
HLPLocationManager is a BLE beacon-based localization Framework for iOS.

## Dependencies
- [blelocpp](https://github.com/hulop/blelocpp) (MIT License)

## Installation

1. Install [Carthage](https://github.com/Carthage/Carthage).
2. Add below to your `Cartfile`:
```
github "hulop/HLPLocationManager"
```
3. In your project directory, run `carthage update`.

## Usage

### Basic

- Implement HLPLocationManagerDelegate

This delegate enables to receive location information.
You should implement methods below.

```
- (void)locationManager:(HLPLocationManager*)manager didLocationUpdate:(HLPLocation*)location;
- (void)locationManager:(HLPLocationManager*)manager didLocationStatusUpdate:(HLPLocationStatus)status;
- (void)locationManager:(HLPLocationManager*)manager didUpdateOrientation:(double)orientation withAccuracy:(double)accuracy;
```

- Setup HLPLocationManager

```objc
HLPLocationManager *manager = [HLPLocationManager sharedManager];
manager.delegate = self;
[manager setModelPath:modelPath];
[manager start];
```

----
## HLPLocationManager
- `isActive` - __readonly__ If `YES`, Localization started.
- `isBackground` - Set to allow background location updates.
  - `YES` - Allow
  - `NO` (default) - Disallow
- `isAccelerationEnabled` - set to use Accelerometer.
  - `YES` (default) - Use Accelerometer
  - `NO` - Don't use Accelerometer
- `currentStatus` - __readonly__ Current LocationManager status.
- `(void)setModelPath:(NSString*)modelPath;`
  - set path to a [model file](https://github.com/hulop/NavCogIOSv3/wiki/Prepare-data-for-localization) for localization.
- `(void)start;`
  - Start localization.
- `(void)restart;`
  - Restart localization.
- `(void)stop;`
  - Stop localization.
- `(void)makeStatusUnknown;`
  - Set bleloc Status to Status::UNKNOWN.
- `(void)resetLocation:(HLPLocation*)loc;`
  - Set location forced.


----
## About
[About HULOP](https://github.com/hulop/00Readme)

## License
[MIT](https://opensource.org/licenses/MIT)

## README
This Human Scale Localization Platform library is intended solely for use with an Apple iOS product and intended to be used in conjunction with officially licensed Apple development tools and further customized and distributed under the terms and conditions of your licensed Apple developer program.
