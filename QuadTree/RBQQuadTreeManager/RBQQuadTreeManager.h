//
//  RBQQuadTreeManager.h
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "RBQIndexRequest.h"

// Quad Tree Realm Objects
#import "RBQQuadTreeDataObject.h"
#import "RBQQuadTreeNodeObject.h"
#import "RBQBoundingBoxObject.h"
#import "RBQQuadTreePropertiesObject.h"

@class RBQQuadTreeManager;

/**
 *  Block that is used by retrieval methods of RBQQuadTreeManager to pass back identified data for the given query.
 *
 *  @param data RBQQuadTreeDataObject that matched the given query.
 */
typedef void(^RBQDataReturnBlock)(RBQQuadTreeDataObject *data);

/**
 *  Convert a RBQQuadTreeIndexState into a NSString description
 *
 *  @param state A RBQQuadTreeIndexState state
 *
 *  @return NSString description
 */
extern NSString * RBQNSStringFromQuadTreeIndexState(RBQQuadTreeIndexState state);

/**
 *  Convert a MKZoomScale to zoom level (log function)
 *
 *  @param scale MKMapView's MKZoomScale
 *
 *  @return zoom level for the given MKZoomScale
 */
extern NSInteger RBQZoomScaleToZoomLevel(MKZoomScale scale);

/**
 *  Function to identify the cluster cell size for a given MKZoomScale
 *
 *  @param zoomScale MKMapView's MKZoomScale
 *
 *  @return Cluster cell size
 */
extern float RBQCellSizeForZoomScale(MKZoomScale zoomScale);

/**
 *  Delegate methods to pass along the status of any indexing that is occurring in RBQQuadTreeManager
 */
@protocol RBQQuadTreeManagerDelegate <NSObject>

@optional

/**
 *  Reports to the delegate that the manager is about to begin indexing
 *
 *  @param manager  The instance of RBQQuadTreeManager
 *  @param state    The current state of the indexing process
 */
- (void)managerWillBeginIndexing:(RBQQuadTreeManager *)manager
                    currentState:(RBQQuadTreeIndexState)state;

/**
 *  Reports to the delegate that the manager updated its percent indexed
 *
 *  @param manager        The instance of RBQQuadTreeManager
 *  @param state          The current state of the indexing process
 *  @param percentIndexed The percent indexed in the current indexing operation
 */
- (void)managerDidUpdate:(RBQQuadTreeManager *)manager
            currentState:(RBQQuadTreeIndexState)state
          percentIndexed:(CGFloat)percentIndexed;

/**
 *  Reports to the delegate that the manager did finish indexing
 *
 *  @param manager  The instance of RBQQuadTreeManager
 *  @param state    The current state of the indexing process
 */
- (void)managerDidEndIndexing:(RBQQuadTreeManager *)manager
                 currentState:(RBQQuadTreeIndexState)state;

@end

/**
 *  This class manages a quad tree index that is backed by a unique Realm database.
 */
@interface RBQQuadTreeManager : NSObject

/**
 *  Object that conforms to RBQQuadTreeManagerDelegate to receive callbacks from the manager
 */
@property (nonatomic, weak) id<RBQQuadTreeManagerDelegate> delegate;

/**
 *  The RBQIndexRequest instance used by the RBQQuadTreeManager
 */
@property (nonatomic, readonly) RBQIndexRequest *indexRequest;

/**
 *  Check to see if the manager is currently indexing data
 */
@property (nonatomic, readonly) BOOL isIndexing;

/**
 *  Obtain an instance of RBQQuadTreeManager that manages an index for a specific index request
 *
 *  @param indexRequest A RBQIndexRequest that defines the index
 *
 *  @return A RBQQuadTreeManager instance
 */
+ (instancetype)managerForIndexRequest:(RBQIndexRequest *)indexRequest;

/**
 *  Enables the RBQQuadTreeManager to listen for changes from RBQRealmNotificationManager and to index on demand
 */
+ (void)startOnDemandIndexingForIndexRequest:(RBQIndexRequest *)indexRequest;

/**
 *  Turns off monitoring for changes and on-demand indexing
 */
+ (void)stopOnDemandIndexingForIndexRequest:(RBQIndexRequest *)indexRequest;

/**
 *  Add a RLMObject to the quad tree index. The process works by immediately persisting the object and then asynchronously indexing the object.
 *
 *  @param object RLMObject to be indexed
    @warning *Important:* The class name for the RLMObject must match the entity name for the RBQQuadTreeManager. Others will be silently ignored.
 */
- (void)insertObject:(RLMObject *)object;

/**
 *  Add a collection of RLMObject's to the quad tree index
 *
 *  @param object Collection of RLMObjects that conforms to NSFastEnumeration
    @warning *Important:* The class name for all of the RLMObjects must match the entity name for the RBQQuadTreeManager. Others will be silently ignored.
 */
- (void)insertObjects:(id<NSFastEnumeration>)objects;

/**
 *  Remove a RLMObject from the quad tree index
 *
 *  @param object RLMObject to be removed from the index
    @warning *Important:* The class name for the RLMObject must match the entity name for the RBQQuadTreeManager. Others will be silently ignored.
 */
- (void)removeObject:(RLMObject *)object;

/**
 *  Remove a collection of RLMObjects' from the quad tree index
 *
 *  @param objects Collection of RLMObjects that conforms to NSFastEnumeration
 @warning *Important:* The class name for all of the RLMObjects must match the entity name for the RBQQuadTreeManager. Others will be silently ignored.
 */
- (void)removeObjects:(id<NSFastEnumeration>)objects;

/**
 *  The method performs a query on the quad tree for a given MKMapRect area and returns the data within it.
 *
 *  @param mapRect MKMapRect the encompasses the search area
 *  @param block   RBQDataReturnBlock which fires every time a data point is found within the area.
 */
- (void)retrieveDataInMapRect:(MKMapRect)mapRect
              dataReturnBlock:(RBQDataReturnBlock)block;

- (NSSet *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect
                               withZoomScale:(MKZoomScale)zoomScale
                                titleKeyPath:(NSString *)titleKeyPath
                             subTitleKeyPath:(NSString *)subTitleKeyPath;

- (void)displayAnnotations:(NSSet *)annotations onMapView:(MKMapView *)mapView;

@end
