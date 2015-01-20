//
//  RBQQuadTreeNodeObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBQBoundingBoxObject.h"
#import "RBQSafeMutableSet.h"

@class RBQBoundingBoxObject, RBQQuadTreeDataObject;

/**
 *  Class used by RBQQuadTreeManager to represent a node within the quad tree data structure.
 
 @warning *Important:* This class should not be used by itself and is used internally be the RBQQuadTreeManager.
 */
@interface RBQQuadTreeNodeObject : NSObject <NSCopying, NSCoding>

/**
 *  Unique key used to identify the node (shares the same key with the bounding box).
 */
@property (nonatomic, readonly) NSString *key;

/**
 *  If the node has been subdivided, this relationship will exist representing the north west quadrant of the subdivided node.
 */
@property (nonatomic, strong) RBQQuadTreeNodeObject *northWest;

/**
 *  If the node has been subdivided, this relationship will exist representing the north east quadrant of the subdivided node.
 */
@property (nonatomic, strong) RBQQuadTreeNodeObject *northEast;

/**
 *  If the node has been subdivided, this relationship will exist representing the south west quadrant of the subdivided node.
 */
@property (nonatomic, strong) RBQQuadTreeNodeObject *southWest;

/**
 *  If the node has been subdivided, this relationship will exist representing the south east quadrant of the subdivided node.
 */
@property (nonatomic, strong) RBQQuadTreeNodeObject *southEast;


/**
 *  The bounding box object that represents the boudaries covered by this node.
 */
@property (nonatomic, readonly) RBQBoundingBoxObject *boundingBox;

/**
 *  To-many relationship to RBQQuadTreeDataObjects which represent the points on the map indexed in this node.
 */
@property (nonatomic, readonly) RBQSafeMutableSet *points;

/**
 *  Capacity of points allowed within this node.
 */
@property (nonatomic, readonly) int bucketCapacity;

/**
 *  Constructor class method to create a RBQQuadTreeNodeObject from a given set of property values.
 
    @warning *Important:* This is the recommended way to construct a RBQQuadTreeNodeObject.
 *
 *  @param box      RBQBoundingBox representing the area covered by this node (must have a unique key)
 *  @param capacity Capacity limit of RBQQuadTreeDataObject points for this node
 *
 *  @return New Instance of RBQQuadTreeNodeObject
 */
+ (instancetype)createQuadTreeNodeWithBox:(RBQBoundingBoxObject *)box
                           bucketCapacity:(int)capacity;

@end
