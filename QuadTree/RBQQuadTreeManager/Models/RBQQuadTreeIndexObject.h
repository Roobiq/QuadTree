//
//  RBQQuadTreeIndexObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBQIndexRequest.h"
#import "RBQQuadTreeNodeObject.h"
#import "RBQSafeMutableSet.h"
#import "RBQQuadTreeDataObject.h"

/**
 *  These values represent the current state of the quad tree index
 */
typedef NS_ENUM(NSInteger, RBQQuadTreeIndexState){
    /**
     *  The quad tree index is not currently processing
     */
    RBQQuadTreeIndexStateReady = 0,
    /**
     *  The quad tree index is currently processing indexing
     */
    RBQQuadTreeIndexStateIndexing,
    /**
     *  The quad tree index contains no data
     */
    RBQQuadTreeIndexStateNoData
};

/**
 *  Convert a RBQQuadTreeIndexState into a NSString description
 *
 *  @param state A RBQQuadTreeIndexState state
 *
 *  @return NSString description
 */
extern NSString * RBQStringFromQuadTreeIndexState(RBQQuadTreeIndexState state);

/**
 *  The class acts as the parent object to the quad tree index.
 */
@interface RBQQuadTreeIndexObject : NSObject <NSCopying, NSCoding>

/**
 *  Unique key used to identify the RBQQuadTreePropertiesObject. Set as the hash of RBQIndexRequest by RBQQuadTreeManager.
 */
@property (nonatomic, readonly) NSInteger key;

/**
 *  The root node of this index (has bounding box that includes the entire globe).
 */
@property (nonatomic, readonly) RBQQuadTreeNodeObject *rootNode;

/**
 *  The state of the quad tree index. This property is set to RBQQuadTreeIndexStateIndexing when any processing begins. Once the indexing is complete it is set to RBQQuadTreeIndexStateReady.
 
    If the process is interrupted, the next time startOnDemandIndexingForIndexRequest: is called on RBQQuadTreeManager, a complete re-indexing will occur.
 */
@property (nonatomic, assign) RBQQuadTreeIndexState indexState;

/**
 *  The total number of points after a full indexing in the quad tree.
 */
@property (nonatomic, assign) NSInteger totalInitialPoints;

/**
 *  Mutable collection to hold every RBQQuadTreeDataObject in the tree
 */
@property (nonatomic, readonly) RBQSafeMutableSet *allPoints;

/**
 *  Constructor method to create a RBQQuadTreeIndexObject
 *
 *  @param indexRequest RBQIndexRequest used to setup the RBQQuadTreeManager
 *
 *  @return A new instance of RBQQuadTreeIndexObject
 */
+ (instancetype)createQuadTreeIndexWithIndexRequest:(RBQIndexRequest *)indexRequest;

/**
 *  Retrieve the RBQQuadTreeDataObject in the index for a given RLMObject
 *
 *  @param object RLMObject that is represented in the index
 *
 *  @return Instance of RBQQuadTreeDataObject, nil if not found.
 */
- (RBQQuadTreeDataObject *)dataForObject:(RLMObject *)object;

/**
 *  Retrieve the RBQQuadTreeDataObject in the index for a given RBQSafeRealmObject
 *
 *  @param safeObject RBQSafeRealmObject that is represented in the index
 *
 *  @return Instance of RBQQuadTreeDataObject, nil if not found.
 */
- (RBQQuadTreeDataObject *)dataForSafeObject:(RBQSafeRealmObject *)safeObject;

/**
 *  Insert RBQQuadTreeDataObject into the index. This adds the data to the allPoints collection and then indexes the data from the root node.
 *
 *  @param data A RBQQuadTreeDataObject instance
 */
- (void)insertAndIndexData:(RBQQuadTreeDataObject *)data;

/**
 *  Remove the RBQQuadTreeDataObject from the index. This removes the data from the allPoints collection and then removes the data from the collection on its parent node.
 *
 *  @param data A RBQQuadTreeDataObject instance
 */
- (void)removeData:(RBQQuadTreeDataObject *)data;

/**
 *  Removes the current index.
 */
- (void)resetIndex;

/**
 *  Removes all the data and resets the index
 */
- (void)resetDataAndIndex;

/**
 *  BOOL to check if the quad tree needs to be re-indexed. If more than 20% of the original points have beeen removed, a full re-indexing needs to occur.
 *
 *  @param deleteCount potential delete count
 *
 *  @return BOOL indicating if the index should be rebuilt versus the items deleted from it
 */
- (BOOL)needsIndexingIfDeleteCount:(NSUInteger)deleteCount;

@end
