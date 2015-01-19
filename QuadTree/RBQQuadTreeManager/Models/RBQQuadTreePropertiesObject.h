//
//  RBQQuadTreePropertiesObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/16/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "RBQIndexRequest.h"

/**
 *  These values represent the current state of the quad tree index
 */
typedef NS_ENUM(NSInteger, RBQQuadTreeIndexState){
    /**
     *  The quad tree index is not currently processing
     */
    RBQQuadTreeIndexStateReady = 0,
    /**
     *  The quad tree index is currently saving data to the Realm for the index
     */
    RBQQuadTreeIndexStatePreparingData,
    /**
     *  The quad tree index is currently processing indexing
     */
    RBQQuadTreeIndexStateIndexing
};

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
 *  The state of the quad tree index. This property is set to RBQQuadTreeIndexStateIndexing when any processing begins. Once the indexing is complete it is set to RBQQuadTreeIndexStateReady. 
 
    If the process is interrupted, the next time startOnDemandIndexingForIndexRequest: is called on RBQQuadTreeManager, a complete re-indexing will occur.
 */
@property NSInteger quadTreeIndexState;

/**
 *  The current total number of points in the quad tree.
 */
@property (readonly) NSInteger totalPoints;

/**
 *  BOOL to check if the quad tree needs to be re-indexed. If more than 20% of the original points have beeen removed, a full re-indexing needs to occur.
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
