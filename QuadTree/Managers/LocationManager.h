//
//  LocationManager.h
//  YoForce
//
//  Created by Adam Fish on 10/11/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#pragma mark - Constants
extern NSString *const kRBQLocationManagerDidUpdateLocation;
extern NSString *const kRBQLocationManagerDidFailWithError;
extern NSString *const kRBQLocationManagerErrorDomain;

typedef enum {
    RBQLocationManagerErrorTimeout = 0,
    RBQLocationManagerErrorCannotLocate = 1,
} RBQLocationManagerError;

typedef void (^LocationFoundBlock)(CLLocation *location);
typedef void (^LocationPermissionGrantedBlock)(CLLocation *location);
typedef void (^LocationFailedBlock)(NSError *error);

@interface LocationManager : NSObject

@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, readonly) BOOL isUpdatingLocation;

@property (nonatomic, readonly) BOOL isMonitoringSignificantLocationChanges;

@property (nonatomic, strong) CLLocationManager *internalLocationManager;

#pragma mark - Class Methods

+ (LocationManager *)defaultManager;

// Call this to check for location services
+ (void)startLocatingForPermissionWithUpdateBlock:(LocationPermissionGrantedBlock)didGrantAccess
                                      failedBlock:(LocationFailedBlock)didFail;

#pragma mark - Instance Methods

- (void)toggleLocationUpdating:(BOOL)enabled;

- (void)toggleSignificantLocationChangeMonitoring:(BOOL)enabled;

@end
