//
//  RBQQuadTreeDataObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import <MapKit/MapKit.h>

#import "RBQQuadTreeNodeObject.h"
#import "RBQSafeRealmObject.h"

@class RBQQuadTreeNodeObject;

/**
 *  Class used by RBQQuadTreeManager that represents a model for data points within a quad tree data structure. Any RLMObject with coordinate information can be represented as RBQQuadTreeDataObjects and indexed by the RBQQuadTreeManager.
 
    @warning *Important:* This class should not be used by itself and is used internally be the RBQQuadTreeManager.
 */
@interface RBQQuadTreeDataObject : RLMObject <NSCopying>

/**
 *  Original RLMObject class name this coordinate data is tied to.
 */
@property NSString *className;

/**
 *  Primary key value represented as a string.
 */
@property NSString *primaryKeyStringValue;

/**
 *  Primary key type. Can be RLMPropertyTypeString or RLMPropertyTypeInt. Stored to assist in converting the primary key value into its original state.
 */
@property RLMPropertyType primaryKeyType;

/**
 *  Latitude value for data point. Default value is invalid.
 */
@property double latitude;

/**
 *  Longitude value for data point. Default value is invalid.
 */
@property double longitude;

/**
 *  Transient (ignored) property to store the current distance of this data from a search center.
 */
@property double currentDistance;

/**
 *  Transient property setup as a convenience to retrieve coordinate from the latitude and longitude values.
 
    Note: the default lat/long are invalid if not set, so use CLLocationCoordinate2DIsValid() if necessary.
 */
@property (readonly) CLLocationCoordinate2D coordinate;

/**
 *  RBQQuadTreeNodeObjects that contain this object.
 */
@property (readonly) NSArray *nodes;

/**
 *  Constructor class method to create a RBQQuadTreeDataObject from a RLMObject and its latitude and longitude key paths
 *
 *  @param object           RLMObject to create a RBQQuadTreeDataObject from
 *  @param latitudeKeyPath  Key path on the RLMObject for the latitude value
 *  @param longitudeKeyPath Key path on the RLMObject for the longitude value
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
 *  @param className             Original RLMObject class name this data object represents
 *  @param primaryKeyStringValue Original RLMObject primary key value represented as a string
 *  @param primaryKeyType        Original RLMObject primary key type
 *  @param latitude              Latitude value
 *  @param longitude             Longitude value
 *
 *  @return New Instance of RBQQuadTreeDataObject
 */
+ (instancetype)createQuadTreeDataObjectForClassName:(NSString *)className
                               primaryKeyStringValue:(NSString *)primaryKeyStringValue
                                      primaryKeyType:(RLMPropertyType)primaryKeyType
                                            latitude:(double)latitude
                                           longitude:(double)longitude;

///**
// *  Convenience method to retrieve the primary key value by converting the string value to the correct value based on the type.
// *
// *  @return Original RLMObject's primary key value. Can be RLMPropertyTypeString or RLMPropertyTypeInt.
// */
//- (id)primaryKeyValue;

/**
 *  Convenience method to retrieve a RBQSafeRealmObject for the original object represented by the data
 *
 *  @return A instance of RBQSafeRealmObject for the original object
 */
- (RBQSafeRealmObject *)originalSafeObject;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQQuadTreeDataObject>
