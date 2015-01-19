//
//  RBQQuadTreeDataObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreeDataObject.h"
#import "RLMObject+Utilities.h"

@implementation RBQQuadTreeDataObject

#pragma mark - Public Class

+ (instancetype)createQuadTreeDataObjectWithObject:(RLMObject *)object
                                   latitudeKeyPath:(NSString *)latitudeKeyPath
                                  longitudeKeyPath:(NSString *)longitudeKeyPath
{
#ifdef DEBUG
    NSAssert(object, @"Object can't be nil");
    NSAssert(latitudeKeyPath, @"Latitude key path can't be nil");
    NSAssert(longitudeKeyPath, @"Longitude key path can't be nil");
#endif
    
    RBQQuadTreeDataObject *dataObject = [[RBQQuadTreeDataObject alloc] init];
    dataObject.className = [RLMObject classNameForObject:object];
    dataObject.primaryKeyType = object.objectSchema.primaryKeyProperty.type;
    
    id primaryKeyValue = [RLMObject primaryKeyValueForObject:object];
    
    if (dataObject.primaryKeyType == RLMPropertyTypeString) {
        dataObject.primaryKeyStringValue = (NSString *)primaryKeyValue;
    }
    else {
        dataObject.primaryKeyStringValue = @((NSInteger)primaryKeyValue).stringValue;
    }
    
    // Get the lat/long
    id latitude = [object valueForKeyPath:latitudeKeyPath];
    id longitude = [object valueForKeyPath:longitudeKeyPath];

#ifdef DEBUG
    NSAssert(latitude, @"No value for latitude key path!");
    NSAssert(longitude, @"No value for longitude key path!");
#endif
    
    if (latitude &&
        longitude) {
        
        dataObject.latitude = [latitude doubleValue];
        dataObject.longitude = [longitude doubleValue];
        
        return dataObject;
    }

    return nil;
}

+ (instancetype)createQuadTreeDataObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                                       latitudeKeyPath:(NSString *)latitudeKeyPath
                                      longitudeKeyPath:(NSString *)longitudeKeyPath
{
    RBQQuadTreeDataObject *dataObject = [[RBQQuadTreeDataObject alloc] init];
    dataObject.className = safeObject.className;
    dataObject.primaryKeyType = safeObject.primaryKeyType;
    
    if (safeObject.primaryKeyType == RLMPropertyTypeString) {
        dataObject.primaryKeyStringValue = (NSString *)safeObject.primaryKeyValue;
    }
    else {
        dataObject.primaryKeyStringValue = @((NSInteger)safeObject.primaryKeyValue).stringValue;
    }
    
    // Retrieve the object
    RLMObject *object = [safeObject RLMObject];
    
    // Get the lat/long
    id latitude = [object valueForKeyPath:latitudeKeyPath];
    id longitude = [object valueForKeyPath:longitudeKeyPath];
    
#ifdef DEBUG
    NSAssert(latitude, @"No value for latitude key path!");
    NSAssert(longitude, @"No value for longitude key path!");
#endif
    
    if (latitude &&
        longitude) {
        
        dataObject.latitude = [latitude doubleValue];
        dataObject.longitude = [longitude doubleValue];
        
        return dataObject;
    }
    
    return nil;
}

+ (instancetype)createQuadTreeDataObjectForClassName:(NSString *)className
                               primaryKeyStringValue:(NSString *)primaryKeyStringValue
                                      primaryKeyType:(RLMPropertyType)primaryKeyType
                                            latitude:(double)latitude
                                           longitude:(double)longitude
{
    RBQQuadTreeDataObject *dataObject = [[RBQQuadTreeDataObject alloc] init];
    dataObject.className = className;
    dataObject.primaryKeyStringValue = primaryKeyStringValue;
    dataObject.primaryKeyType = primaryKeyType;
    dataObject.latitude = latitude;
    dataObject.longitude = longitude;
    
    return dataObject;
}

#pragma mark - RLMObject

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"className": @"",
             @"primaryKeyStringValue" : @"",
             @"primaryKeyType" : @(NSIntegerMin),
             @"latitude" : @91,
             @"longitude" : @181
             };
}

// Specify properties to ignore (Realm won't persist these)

+ (NSArray *)ignoredProperties
{
    return @[@"currentDistance",
             @"coordinate"];
}

+ (NSString *)primaryKey
{
    return @"primaryKeyStringValue";
}

#pragma mark - Public Instance

- (RBQSafeRealmObject *)originalSafeObject
{
    if (self.primaryKeyType == RLMPropertyTypeString) {
        return [[RBQSafeRealmObject alloc] initWithClassName:self.className
                                             primaryKeyValue:self.primaryKeyStringValue
                                              primaryKeyType:self.primaryKeyType
                                                       realm:self.realm];
    }
    
    return [[RBQSafeRealmObject alloc] initWithClassName:self.className
                                         primaryKeyValue:@(self.primaryKeyStringValue.longLongValue)
                                          primaryKeyType:self.primaryKeyType
                                                   realm:self.realm];
}

#pragma mark - Getters

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        return coordinate;
    }
    else {
        return kCLLocationCoordinate2DInvalid;
    }
}

- (NSArray *)nodes
{
   return [self linkingObjectsOfClass:@"RBQQuadTreeNodeObject" forProperty:@"points"]; 
}

#pragma mark - Equality

//- (BOOL)isEqualToObject:(RBQQuadTreeDataObject *)object
//{
//    if (self.primaryKeyType == RLMPropertyTypeString &&
//        object.primaryKeyType == RLMPropertyTypeString) {
//        
//        return [self.primaryKeyStringValue isEqualToString:object.primaryKeyStringValue];
//    }
//    else if (self.primaryKeyType == RLMPropertyTypeInt &&
//             object.primaryKeyType == RLMPropertyTypeInt) {
//        
//        return self.primaryKeyStringValue.integerValue == object.primaryKeyStringValue.integerValue;
//    }
//    else {
//        return [super isEqual:object];
//    }
//}

- (BOOL)isEqual:(id)object
{
    NSString *className = NSStringFromClass(self.class);
    
    if ([className hasPrefix:@"RLMStandalone_"]) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQQuadTreeDataObject *dataObject = [[RBQQuadTreeDataObject allocWithZone:zone] init];
    dataObject.className = self.className;
    dataObject.primaryKeyStringValue = self.primaryKeyStringValue;
    dataObject.primaryKeyType = self.primaryKeyType;
    dataObject.latitude = self.latitude;
    dataObject.longitude = self.longitude;
    
    return dataObject;
    
}

@end
