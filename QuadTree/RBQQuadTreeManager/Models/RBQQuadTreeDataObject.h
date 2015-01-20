//
//  RBQQuadTreeDataObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSafeRealmObject.h"
#import "RBQQuadTreeNodeObject.h"
#import <MapKit/MapKit.h>

@class RBQQuadTreeNodeObject;

/**
 *  Class used by the RBQQuadTreeManager to represent data within the tree. Is a subclass of RBQSafeRealmObject that includes geographical inforamtion.
 */
@interface RBQQuadTreeDataObject : RBQSafeRealmObject <NSCopying, NSCoding>

/**
 *  Latitude value for data point. Default value is invalid.
 */
@property (nonatomic, readonly) CLLocationDegrees latitude;

/**
 *  Longitude value for data point. Default value is invalid.
 */
@property (nonatomic, readonly) CLLocationDegrees longitude;

/**
 *  Transient (ignored) property to store the current distance of this data from a search center.
 */
@property (nonatomic, assign) CLLocationDistance currentDistance;

/**
 *  Transient property setup as a convenience to retrieve coordinate from the latitude and longitude values.
 
    @warning *Important:* The default lat/long are invalid if not set, so use CLLocationCoordinate2DIsValid() if necessary.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 *  The node contains this data object.
 */
@property (nonatomic, strong) RBQQuadTreeNodeObject *node;

/**
 *   Constructor class method to create a RBQQuadTreeDataObject from a RLMObject and its latitude and longitude key paths
 *
 *  @param object    RLMObject to create a RBQQuadTreeDataObject from
 *  @param latitudeKeyPath  Key path for the latitude value on the RLMObject
 *  @param longitudeKeyPath Key path for the longitude value on the RLMObject
 *
 *  @return New Instance of RBQQuadTreeDataObject
 */
+ (instancetype)createQuadTreeDataObjectWithObject:(RLMObject *)object
                                   latitudeKeyPath:(NSString *)latitudeKeyPath
                                  longitudeKeyPath:(NSString *)longitudeKeyPath;

/**
 *  Constructor class method to create a RBQQuadTreeDataObject from a RBQSafeRealmObject and its latitude and longitude key paths
 *
 *  @param safeObject       RBQSafeRealmObject to create a RBQQuadTreeDataObject from
 *  @param latitudeKeyPath  Key path for the latitude value on the RLMObject represented by the RBQSafeRealmObject
 *  @param longitudeKeyPath Key path for the longitude value on the RLMObject represented by the RBQSafeRealmObject
 *
 *  @return New Instance of RBQQuadTreeDataObject
 */
+ (instancetype)createQuadTreeDataObjectWithSafeObject:(RBQSafeRealmObject *)safeObject
                                       latitudeKeyPath:(NSString *)latitudeKeyPath
                                      longitudeKeyPath:(NSString *)longitudeKeyPath;

/**
 *  Constructor class method to create a RBQQuadTreeDataObject from a given set of property values.
 *
 *  @param className       Original RLMObject class name this data object represents
 *  @param realm           Realm in which the RLMObject is persisted
 *  @param primaryKeyValue Original RLMObject primary key value
 *  @param primaryKeyType  Original RLMObject primary key type
 *  @param latitude        Latitude value
 *  @param longitude       Longitude value
 *
 *  @return New Instance of RBQQuadTreeDataObject
 */
+ (instancetype)createQuadTreeDataObjectForClassName:(NSString *)className
                                             inRealm:(RLMRealm *)realm
                                     primaryKeyValue:(id)primaryKeyValue
                                      primaryKeyType:(RLMPropertyType)primaryKeyType
                                            latitude:(CLLocationDegrees)latitude
                                           longitude:(CLLocationDegrees)longitude;

@end
