//
//  RBQQuadTreePropertiesObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/16/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQIndexRequest.h"

@interface RBQQuadTreePropertiesObject : RLMObject

/**
 *  Unique key used to identify the RBQQuadTreePropertiesObject. Set as the hash of RBQIndexRequest by RBQQuadTreeManager.
 */
@property NSInteger key;

/**
 *  The total number of points after a full indexing in the quad tree.
 */
@property NSInteger totalInitialPoints;

/**
 *  The current total number of points in the quad tree.
 */
@property (readonly) NSInteger totalPoints;

/**
 *  BOOL to check if the quad tree needs to be re-indexed.
 */
@property (readonly) BOOL needsIndexing;

/**
 *  Constructor method to create a RBQQuadTreePropertiesObject
 *
 *  @param indexRequest RBQIndexRequest used to setup the RBQQuadTreeManager
 *
 *  @return A new instance of RBQQuadTreePropertiesObject
 */
+ (instancetype)createQuadTreePropertiesWithIndexRequest:(RBQIndexRequest *)indexRequest;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RBQQuadTreePropertiesObject>
RLM_ARRAY_TYPE(RBQQuadTreePropertiesObject)
