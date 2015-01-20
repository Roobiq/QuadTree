//
//  RBQQuadTreeDataObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreeDataObject.h"

@implementation RBQQuadTreeDataObject
@synthesize latitude = _latitude,
longitude = _longitude;

#pragma mark - Public Class

+ (instancetype)createQuadTreeDataObjectWithObject:(RLMObject *)object
                                   latitudeKeyPath:(NSString *)latitudeKeyPath
                                  longitudeKeyPath:(NSString *)longitudeKeyPath
{
    RBQSafeRealmObject *safeObject = [RBQQuadTreeDataObject safeObjectFromObject:object];
    
    return [RBQQuadTreeDataObject createQuadTreeDataObjectWithSafeObject:safeObject
                                                         latitudeKeyPath:latitudeKeyPath
                                                        longitudeKeyPath:longitudeKeyPath];
}

+ (instancetype)createQuadTreeDataObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                                       latitudeKeyPath:(NSString *)latitudeKeyPath
                                      longitudeKeyPath:(NSString *)longitudeKeyPath
{
    RBQQuadTreeDataObject *data = [[RBQQuadTreeDataObject alloc] initWithClassName:safeObject.className
                                                                   primaryKeyValue:safeObject.primaryKeyValue
                                                                    primaryKeyType:safeObject.primaryKeyType
                                                                             realm:safeObject.realm];
    
    RLMObject *object = [data RLMObject];
    
    CLLocationDegrees latitude = ((NSNumber *)[object valueForKeyPath:latitudeKeyPath]).doubleValue;
    CLLocationDegrees longitude = ((NSNumber *)[object valueForKeyPath:longitudeKeyPath]).doubleValue;
    
    data->_latitude = latitude;
    data->_longitude = longitude;
    
    return data;
}

+ (instancetype)createQuadTreeDataObjectForClassName:(NSString *)className
                                             inRealm:(RLMRealm *)realm
                                     primaryKeyValue:(id)primaryKeyValue
                                      primaryKeyType:(RLMPropertyType)primaryKeyType
                                            latitude:(CLLocationDegrees)latitude
                                           longitude:(CLLocationDegrees)longitude
{
    RBQQuadTreeDataObject *data = [[RBQQuadTreeDataObject alloc] initWithClassName:className
                                                                   primaryKeyValue:primaryKeyValue
                                                                    primaryKeyType:primaryKeyType
                                                                             realm:realm];
    
    data->_latitude = latitude;
    data->_longitude = longitude;
    
    return data;
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

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQQuadTreeDataObject *data = [super copyWithZone:zone];
    
    data->_latitude = _latitude;
    data->_longitude = _longitude;
    data->_node = _node;
    
    return data;
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self->_latitude = [decoder decodeDoubleForKey:@"latitude"];
        self->_latitude = [decoder decodeDoubleForKey:@"longitude"];
        self->_node = [decoder decodeObjectForKey:@"node"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeDouble:self.latitude forKey:@"latitude"];
    [encoder encodeDouble:self.longitude forKey:@"longitude"];
    
    if (self.node) {
        [encoder encodeObject:self.node forKey:@"node"];
    }
}


@end
