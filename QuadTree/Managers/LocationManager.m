//
//  LocationManager.m
//  YoForce
//
//  Created by Adam Fish on 10/11/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "LocationManager.h"
#import <NotificationCenter/NotificationCenter.h>

#pragma mark - Constants

#define enableSigChangeReporting NO
#define distanceRequestConstant 161 // In kilometers ~100 miles
#define distanceRequestVersion 7

NSString *const kRBQLocationManagerDidUpdateLocation = @"RBQLocationManagerDidUpdateLocation";
NSString *const kRBQLocationManagerDidFailWithError = @"RBQLocationManagerDidFailWithError";
NSString *const kRBQLocationManagerErrorDomain = @"RBQLocationManagerErrorDomain";

@interface LocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) LocationFailedBlock internalLocationDidFailBlock;
@property (nonatomic, strong) LocationPermissionGrantedBlock internalLocationPermissionGrantedBlock;

@end

@implementation LocationManager

@synthesize isUpdatingLocation = _isUpdatingLocation;
@synthesize isMonitoringSignificantLocationChanges = _isMonitoringSignificantLocationChanges;

#pragma mark - Class Methods

+ (LocationManager *)defaultManager {
    static LocationManager *__LocationManager;
    if (!__LocationManager) {
        __LocationManager = [[LocationManager alloc] init];
    }
    return __LocationManager;
}

+ (void)startLocatingForPermissionWithUpdateBlock:(LocationPermissionGrantedBlock)didGrantAccess
                                      failedBlock:(LocationFailedBlock)didFail {
    
    [LocationManager defaultManager].internalLocationPermissionGrantedBlock = didGrantAccess;
    [LocationManager defaultManager].internalLocationDidFailBlock = didFail;
    
    // For iOS 8 request authorization this way
    if ([[LocationManager defaultManager].internalLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        // If status is not determined then call the autorization
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [[LocationManager defaultManager].internalLocationManager requestWhenInUseAuthorization];
        }
        else { // If not just call the block
            [LocationManager defaultManager].internalLocationPermissionGrantedBlock([LocationManager defaultManager].internalLocationManager.location);
        }
    }
    else {
        // Turn on updating location
        [[LocationManager defaultManager] toggleLocationUpdating:YES];
    }
}

#pragma mark - Instance Methods

- (id)init {
    self = [super init];
    if (self) {
        // Do any additional setup
        _internalLocationManager = ({
            CLLocationManager *manager = [[CLLocationManager alloc] init];
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
            manager.delegate = self;
            manager;
        });
        
        _isUpdatingLocation = NO;
        
        _isMonitoringSignificantLocationChanges = NO;
    }
    return self;
}

#pragma mark - Public

- (void)toggleLocationUpdating:(BOOL)enabled {
    if (enabled &&
        (CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
            
        // Turn on updating location
        [self.internalLocationManager startUpdatingLocation];
        
        _isUpdatingLocation = YES;
    }
    else {
        // Turn off updating location
        [self.internalLocationManager stopUpdatingLocation];
        
        _isUpdatingLocation = NO;
    }
}

- (void)toggleSignificantLocationChangeMonitoring:(BOOL)enabled {
    if (enabled &&
        (CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) &&
        CLLocationManager.significantLocationChangeMonitoringAvailable) {
        
        // Turn on significant location change monitoring
        [self.internalLocationManager startMonitoringSignificantLocationChanges];
        
        _isMonitoringSignificantLocationChanges = YES;
    }
    else {
        // Turn off significant location change monitoring
        [self.internalLocationManager stopMonitoringSignificantLocationChanges];
        
        _isMonitoringSignificantLocationChanges = NO;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (error.domain == kCLErrorDomain && error.code == kCLErrorDenied) {
        if (self.isUpdatingLocation) {
            [self toggleLocationUpdating:NO];
        }
        
        if (self.isMonitoringSignificantLocationChanges) {
            [self toggleSignificantLocationChangeMonitoring:NO];
        }
    }
    
    // Fire error block
    if (self.internalLocationDidFailBlock) {
        self.internalLocationDidFailBlock(error);
        
        self.internalLocationDidFailBlock = nil;
    }
    
    // Post the error to notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kRBQLocationManagerDidFailWithError
                                                        object:error];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied) {
        [self toggleLocationUpdating:NO];
        
        // Fire error block
        if (self.internalLocationDidFailBlock) {
            self.internalLocationDidFailBlock([NSError errorWithDomain:kRBQLocationManagerErrorDomain
                                                                  code:RBQLocationManagerErrorCannotLocate
                                                              userInfo:nil]);
            
            self.internalLocationDidFailBlock = nil;
        }
    }
    else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        // Fire permission granted block
        if (self.internalLocationPermissionGrantedBlock) {
            self.internalLocationPermissionGrantedBlock(manager.location);
            
            // For some reason the fail block will still trigger after success
            self.internalLocationDidFailBlock = nil;
        }
    }
}

@end
