//
//  RBQBoundingBoxObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBQQuadTreeDataObject.h"
#import <MapKit/MapKit.h>

@class RBQBoundingBoxObject, RBQQuadTreeDataObject;

#pragma mark - Functions

/**
 *  Check if the bounding box object contains a data object
 *
 *  @param box  RBQBoundingBoxObject object to test if data resides in
 *  @param data RBQQuadTreeDataObject to test if in bounding box
 *
 *  @return BOOL value indicating if in the bounding box
 */
BOOL boundingBoxContainsData(RBQBoundingBoxObject *box, RBQQuadTreeDataObject *data);

/**
 *  Check if two bounding boxes intersect
 *
 *  @param b1 First RBQBoundingBoxObject
 *  @param b2 Second RBQBoundingBoxObject
 *
 *  @return BOOL value indicating if the bounding boxes intersect
 */
BOOL boundingBoxIntersectsBoundingBox(RBQBoundingBoxObject *b1, RBQBoundingBoxObject *b2);

/**
 *  Create a MKMapRect from a given RBQBoundingBoxObject
 *
 *  @param boundingBox RBQBoundingBoxObject to convert
 *
 *  @return MKMapRect representing the RBQBoundingBoxObject
 */
MKMapRect mapRectForBoundingBox(RBQBoundingBoxObject *boundingBox);

/**
 *  Use to convert a MKMapRect into a RBQBoundingBoxObject
 *
 *  @param mapRect A MKMapRect instance
 *
 *  @return A RBQBoundingBoxObject instance
 */
RBQBoundingBoxObject* boundingBoxForMapRect(MKMapRect mapRect);

#pragma mark - RBQBoundingBoxObject

/**
 *  Class used by RBQQuadTreeManager that represents a bounding box within the quad tree data structure.
 
 @warning *Important:* This class should not be used by itself and is used internally be the RBQQuadTreeManager.
 */
@interface RBQBoundingBoxObject : NSObject <NSCopying, NSCoding>

/**
 *  Unique key used to identify the bounding box.
 */
@property (nonatomic, readonly) NSString *key;

/**
 *  X origin
 */
@property (nonatomic, readonly) double x;

/**
 *  Y origin
 */
@property (nonatomic, readonly) double y;

/**
 *  Height of the bounding box
 */
@property (nonatomic, readonly) double height;

/**
 *  Width of the bounding box
 */
@property (nonatomic, readonly) double width;

/**
 *  Constructor class method to create a RBQBoundingBoxObject from a given set of property values.
 
 @warning *Important:* This is the recommended way to construct a RBQBoundingBoxObject.
 *
 *  @param x      x origin value of box
 *  @param y      y origin value of box
 *  @param width  width value of box
 *  @param height height value of box
 *
 *  @return New Instance of RBQBoundingBoxObject
 */
+ (RBQBoundingBoxObject *)createBoundingBoxWithX:(double)x
                                               y:(double)y
                                           width:(double)width
                                          height:(double)height;

@end
