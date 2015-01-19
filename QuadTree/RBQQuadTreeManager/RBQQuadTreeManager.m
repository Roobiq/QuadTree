//
//  RBQQuadTreeManager.m
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreeManager.h"
#import "RLMObject+Utilities.h"
#import "RBQRealmNotificationManager.h"

#import <MapKit/MapKit.h>

@class RBQNodeInternal;

#pragma mark - Constants

int kRBQDefaultCapacity = 100;
int kRBQMaxCountUntilFulLWipe = 10000;

// Based off of MKMapRectWorld Constant
double kRBQRootNodeX = -85.051128779806603;
double kRBQRootNodeY = -180;
double kRBQRootNodeWidth = 85.051128779806589;
double kRBQRootNodeHeight = 180;

#pragma mark - Global

// Global map to return the same notification manager for each Realm
NSMapTable *entityNameToManagerMap;

// Retrieve the cached RBQQuadTreeManager singleton
RBQQuadTreeManager *cachedQuadTreeManager(NSString *entityName) {
    @synchronized(entityNameToManagerMap) {
        
        // Create the map if not initialized
        if (!entityNameToManagerMap) {
            entityNameToManagerMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                           valueOptions:NSPointerFunctionsStrongMemory];
            
            return nil;
        }
        
        return [entityNameToManagerMap objectForKey:entityName];
    }
}

#pragma mark - Public Functions

NSString * NSStringFromQuadTreeIndexState(RBQQuadTreeIndexState state) {
    switch (state) {
        case RBQQuadTreeIndexStatePreparingData:
            return @"Preparing Data";
        case RBQQuadTreeIndexStateIndexing:
            return @"Indexing";
        case RBQQuadTreeIndexStateReady:
            return @"Ready";
        default:
            return nil;
    }
}

#pragma mark - RBQQuadTreeManager

@interface RBQQuadTreeManager ()

@property (nonatomic, strong) dispatch_queue_t serialIndexQueue;

@property (strong, nonatomic) RBQNotificationToken *notificationToken;

@end

@implementation RBQQuadTreeManager
@synthesize isIndexing = _isIndexing,
indexRequest = _indexRequest;

#pragma mark - Constructors

- (id)init
{
    self = [super init];
    
    if (self) {
        _serialIndexQueue = dispatch_queue_create("com.Roobiq.RBQQuadTreeManager.indexQueue",
                                                  DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - Public Class

+ (instancetype)managerForIndexRequest:(RBQIndexRequest *)indexRequest
{
#ifdef DEBUG
    NSAssert(indexRequest, @"Index request must not be nil!");
    NSAssert(indexRequest.entityName, @"Entity name must not be nil!");
    NSAssert(indexRequest.latitudeKeyPath, @"Latitude key path must not be nil!");
    NSAssert(indexRequest.longitudeKeyPath, @"Longitude key path must not be nil!");
#endif
    
    RBQQuadTreeManager *manager = cachedQuadTreeManager(indexRequest.entityName);
    
    if (!manager) {
        manager = [[self alloc] init];
        manager->_indexRequest = indexRequest;
        
        // Add the manager to the cache
        @synchronized(entityNameToManagerMap) {
            [entityNameToManagerMap setObject:manager forKey:indexRequest.entityName];
        }
        
        // Create and save a unique RBQQuadTreePropertiesObject
        RLMRealm *realmIndex = [manager currentRealmIndex];
        
        RBQQuadTreePropertiesObject *properties = [RBQQuadTreePropertiesObject objectInRealm:realmIndex
                                                                               forPrimaryKey:@(indexRequest.hash)];
        
        if (!properties) {
            properties = [RBQQuadTreePropertiesObject createQuadTreePropertiesWithIndexRequest:indexRequest];
            
            [realmIndex beginWriteTransaction];
            
            [realmIndex addObject:properties];
            
            [realmIndex commitWriteTransaction];
        }
    }
    
    return manager;
}

+ (void)startOnDemandIndexingForIndexRequest:(RBQIndexRequest *)indexRequest
{
    RBQQuadTreeManager *manager = [RBQQuadTreeManager managerForIndexRequest:indexRequest];
    
    if (!manager.notificationToken) {
        [manager registerNotifications];
    }
    
    // Dispatch a process to check if we need to rebuild the index
    dispatch_async(manager.serialIndexQueue, ^(){
        
        RBQQuadTreePropertiesObject *properties = [manager currentQuadTreeProperties];
        
        // The indexing was interrupted, restart it
        if (properties.quadTreeIndexState == RBQQuadTreeIndexStateIndexing) {
            
            [manager rebuildIndex];
        }
        else if (properties.quadTreeIndexState == RBQQuadTreeIndexStatePreparingData) {
            // Get all the data from the track entity
            
            [manager reloadAllDataAndIndex];
        }
    });
}

+ (void)stopOnDemandIndexingForIndexRequest:(RBQIndexRequest *)indexRequest
{
    RBQQuadTreeManager *manager = [RBQQuadTreeManager managerForIndexRequest:indexRequest];
    
    if (manager.notificationToken) {
        [manager unregisterNotifications];
    }
}

#pragma mark - Public Instance

- (void)insertObject:(RLMObject *)object
{
    NSString *className = [RLMObject classNameForObject:object];
    if ([className isEqualToString:self.indexRequest.entityName]) {
        
        NSSet *safeObjects = [self addOrUpdateObjectsInIndexAndReturnSafeObjects:@[object]
                                                                 processingCount:1];
        
        [self indexSafeObjects:safeObjects forceFullWipe:NO];
    }
}

- (void)insertObjects:(id<NSFastEnumeration>)objects
{
    NSUInteger count = (NSUInteger)[(NSObject *)objects valueForKey:@"count"];
    
    NSSet *safeObjects = [self addOrUpdateObjectsInIndexAndReturnSafeObjects:objects
                                                             processingCount:count];
    
    [self indexSafeObjects:safeObjects forceFullWipe:NO];
}

- (void)removeObject:(RLMObject *)object
{
    [self deleteObjectsInIndex:@[object]];
}

- (void)removeObjects:(id<NSFastEnumeration>)objects
{
    [self deleteObjectsInIndex:objects];
}

- (void)retrieveDataInMapRect:(MKMapRect)mapRect
              dataReturnBlock:(RBQDataReturnBlock)block
{
    RBQQuadTreeNodeObject *rootNode = [self currentRootNode];
    RBQBoundingBoxObject *boundingBox = boundingBoxForMapRect(mapRect);
    
    [self quadTreeGatherDataWithRange:rootNode
                          boundingBox:boundingBox
                      dataReturnBlock:block];
}

#pragma mark - Private

- (void)registerNotifications
{
    // Register for changes from the Realm in which the object to be indexed is persisted
    RBQRealmNotificationManager *notificationManager =
    [RBQRealmNotificationManager managerForRealm:self.indexRequest.realm];
    
    self.notificationToken = [notificationManager addNotificationBlock:^(NSDictionary *entityChanges,
                                                                         RLMRealm *realm) {
        
        RBQEntityChangesObject *entityChangesObject = [entityChanges objectForKey:self.indexRequest.entityName];
        
        if (entityChangesObject) {
            
            dispatch_async(self.serialIndexQueue, ^(){
                // Gather up all of the safe objects that will be indexed
                NSSet *allSafeObjectsToIndex = [entityChangesObject.addedSafeObjects setByAddingObjectsFromSet:entityChangesObject.changedSafeObjects];
                
                if (allSafeObjectsToIndex.count > 0) {
                    [self updatePropertiesState:RBQQuadTreeIndexStateIndexing];
                    
                    [self addOrUpdateSafeObjectsInIndex:allSafeObjectsToIndex];
                    
                    [self indexSafeObjects:allSafeObjectsToIndex forceFullWipe:NO];
                }
                
                if (entityChangesObject.deletedSafeObjects.count > 0) {
                    [self deleteObjectsWithSafeObjectsInIndex:entityChangesObject.deletedSafeObjects];
                }
            });
        }
    }];
}

- (void)unregisterNotifications
{
    // Remove the notification for the object to be indexed
    RBQRealmNotificationManager *notificationManager =
    [RBQRealmNotificationManager managerForRealm:self.indexRequest.realm];
    
    [notificationManager removeNotification:self.notificationToken];
    
    self.notificationToken = nil;
}

#pragma mark - Add/Delete Index Data

// Return an array of RBQSafeRealmObjects
- (NSSet *)addOrUpdateObjectsInIndexAndReturnSafeObjects:(id<NSFastEnumeration>)objects
                                         processingCount:(NSUInteger)processingCount
{
    @autoreleasepool {
        
        [self updatePropertiesState:RBQQuadTreeIndexStatePreparingData];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerWillBeginIndexing:currentState:)]) {
                [self.delegate managerWillBeginIndexing:self
                                           currentState:RBQQuadTreeIndexStatePreparingData];
            }
            
        });
        
        NSMutableSet *safeObjects = [[NSMutableSet alloc] initWithCapacity:processingCount];
        
        RLMRealm *realmIndex = [self currentRealmIndex];
        
        NSLog(@"Started Writing Objects To Index");
        
        [realmIndex beginWriteTransaction];
        
        NSUInteger count = 0;
        
        for (RLMObject *object in objects) {
            count ++;
            
            RBQQuadTreeDataObject *data =
            [RBQQuadTreeDataObject createQuadTreeDataObjectWithObject:object
                                                      latitudeKeyPath:self.indexRequest.latitudeKeyPath
                                                     longitudeKeyPath:self.indexRequest.longitudeKeyPath];
            
            [realmIndex addOrUpdateObject:data];
            
            CGFloat percentIndexed = (CGFloat)count/(2.f * processingCount);
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                    [self.delegate managerDidUpdate:self
                                       currentState:RBQQuadTreeIndexStatePreparingData
                                     percentIndexed:percentIndexed];
                }
                
            });
            
            [safeObjects addObject:[RBQSafeRealmObject safeObjectFromObject:data]];
        }
        
        [realmIndex commitWriteTransaction];
        
        NSLog(@"Finished Writing Objects To Index");
        
        return safeObjects.copy;
    }
}

- (void)addOrUpdateSafeObjectsInIndex:(NSSet *)safeObjects
{
    @autoreleasepool {
        [self updatePropertiesState:RBQQuadTreeIndexStatePreparingData];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerWillBeginIndexing:currentState:)]) {
                [self.delegate managerWillBeginIndexing:self
                                           currentState:RBQQuadTreeIndexStatePreparingData];
            }
            
        });
        
        RLMRealm *realmIndex = [self currentRealmIndex];
        
        NSLog(@"Started Writing Objects To Index");
        
        [realmIndex beginWriteTransaction];
        
        NSUInteger count = 0;
        
        for (RBQSafeRealmObject *object in safeObjects) {
            
            count ++;
            
            RBQQuadTreeDataObject *data =
            [RBQQuadTreeDataObject createQuadTreeDataObjectWithSafeObject:object
                                                          latitudeKeyPath:self.indexRequest.latitudeKeyPath
                                                         longitudeKeyPath:self.indexRequest.longitudeKeyPath];
            
            [realmIndex addOrUpdateObject:data];
            
            CGFloat percentIndexed = (CGFloat)count/(CGFloat)(2 * safeObjects.count);
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                    [self.delegate managerDidUpdate:self
                                       currentState:RBQQuadTreeIndexStatePreparingData
                                     percentIndexed:percentIndexed];
                }
                
            });
        }
        
        [realmIndex commitWriteTransaction];
        
        NSLog(@"Finished Writing Objects To Index");
    }
}

- (void)deleteObjectsInIndex:(id<NSFastEnumeration>)objects
{
    @autoreleasepool {
        NSLog(@"Started Deleting Objects To Index");
        
        RLMRealm *realmIndex = [self currentRealmIndex];

        [realmIndex beginWriteTransaction];
    
        [realmIndex deleteObjects:objects];
    
        [realmIndex commitWriteTransaction];
    
        RBQQuadTreePropertiesObject *properties = [self currentQuadTreePropertiesInRealm:realmIndex];
    
        if (properties.needsIndexing) {
            [self rebuildIndex];
        }
    }
}

- (void)deleteObjectsWithSafeObjectsInIndex:(NSSet *)safeObjects
{
    @autoreleasepool {
        NSLog(@"Started Deleting Objects To Index");
        
        RLMRealm *realmIndex = [self currentRealmIndex];
        
        [realmIndex beginWriteTransaction];
        
        for (RBQSafeRealmObject *safeObject in safeObjects) {
            
            RBQQuadTreeDataObject *data = [RBQQuadTreeDataObject objectInRealm:realmIndex
                                                                 forPrimaryKey:safeObject.primaryKeyValue];
            
            if (data) {
                [realmIndex deleteObject:data];
            }
        }
    
        [realmIndex commitWriteTransaction];
        
        NSLog(@"Finished Deleting Objects To Index");
    
        RBQQuadTreePropertiesObject *properties = [self currentQuadTreePropertiesInRealm:realmIndex];
        
        if (properties.needsIndexing) {
            [self rebuildIndex];
        }
    }
}

#pragma mark - Indexing Methods

- (void)indexSafeObjects:(NSSet *)safeObjects
           forceFullWipe:(BOOL)fullWipe
{
    dispatch_async(self.serialIndexQueue, ^(){
        NSLog(@"Started Building Quad Tree");
        
        [self updatePropertiesState:RBQQuadTreeIndexStateIndexing];
        
        // If we have a lot of safe objects, then clear index and start from scratch
        if (safeObjects.count > kRBQMaxCountUntilFulLWipe ||
            [RBQQuadTreeDataObject allObjectsInRealm:[self currentRealmIndex]].count == 0 ||
            fullWipe) {
            
            [self clearIndex];
        }
    
        [self performIndexingWithSafeObjects:safeObjects];
        
        NSLog(@"Finished Building Quad Tree");
    });
}

- (void)reloadAllDataAndIndex
{
    dispatch_async(self.serialIndexQueue, ^(){
        RLMResults *allData = [NSClassFromString(self.indexRequest.entityName) allObjectsInRealm:self.indexRequest.realm];
        
        NSSet *safeObjects = [self addOrUpdateObjectsInIndexAndReturnSafeObjects:allData
                                                                 processingCount:allData.count];
        
        [self indexSafeObjects:safeObjects forceFullWipe:YES];
    });
}

- (void)rebuildIndex
{
    dispatch_async(self.serialIndexQueue, ^(){
        NSLog(@"Started Re-building Quad Tree");
        
        [self updatePropertiesState:RBQQuadTreeIndexStateIndexing];
        
        [self clearIndex];
        
        RLMRealm *realmIndex = [self currentRealmIndex];
        
        RLMResults *allData = [RBQQuadTreeDataObject allObjectsInRealm:realmIndex];
        
        [self performIndexingInRealm:realmIndex
                         withAllData:allData];
        
        NSLog(@"Finished Re-building Quad Tree");
    });
}

- (void)clearIndex
{
    NSLog(@"Started Index Wipe");
    RLMRealm *realmIndex = [self currentRealmIndex];
    
    [realmIndex beginWriteTransaction];
    
    RLMResults *allNodes = [RBQQuadTreeNodeObject allObjectsInRealm:realmIndex];
    
    [realmIndex deleteObjects:allNodes];
    
    RLMResults *allBoxes = [RBQBoundingBoxObject allObjectsInRealm:realmIndex];
    
    [realmIndex deleteObjects:allBoxes];
    
    [realmIndex commitWriteTransaction];
    NSLog(@"Finished Index Wipe");
}

- (void)performIndexingWithSafeObjects:(NSSet *)safeObjects
{
    @autoreleasepool {
        _isIndexing = YES;
        
        // We already called the willBegin delegate as part of the inital data processing
        
        RLMRealm *realmIndex = [self realmForEntityName:self.indexRequest.entityName];
        
        RBQQuadTreeNodeObject *rootNode = [self rootNodeInRealm:realmIndex];
        
        [realmIndex beginWriteTransaction];
        
        NSUInteger index = 0;
        
        for (RBQSafeRealmObject *safeObject in safeObjects) {
            RBQQuadTreeDataObject *data = [RBQQuadTreeDataObject objectInRealm:realmIndex
                                                                 forPrimaryKey:safeObject.primaryKeyValue];
#ifdef DEBUG
            NSAssert(data, @"Data can't be nil!");
#endif
            
            [self quadTreeNode:rootNode
                    insertData:data];
            
            index ++;
            
            /* Percent indexed is based off of 2x the object count since we are already at 50%
             since 'indexing' includes saving the objects as RBQQuadTreeDataObjects
             */
            CGFloat percentIndexed = ((CGFloat)index + (CGFloat)safeObjects.count)/(CGFloat)(safeObjects.count * 2);
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                    
                    [self.delegate managerDidUpdate:self
                                       currentState:RBQQuadTreeIndexStateIndexing
                                     percentIndexed:percentIndexed];
                }
            });
            
            if (index % 1000 == 0) {
                NSLog(@"Index: %lu",(unsigned long)index);
            }
        }
        
        [realmIndex addOrUpdateObject:rootNode];
        
        [realmIndex commitWriteTransaction];
    
        // Update the number of points in the quad tree
        [self updatePropertiesPointsCountInRealm:realmIndex];
        
        // Update the state that we are finished
        [self updatePropertiesState:RBQQuadTreeIndexStateReady];
    
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:currentState:)]) {
                [self.delegate managerDidEndIndexing:self currentState:RBQQuadTreeIndexStateReady];
            }
        });
        
        _isIndexing = NO;
    }
}

// Only called without any inserts
- (void)performIndexingInRealm:(RLMRealm *)realmIndex
                   withAllData:(RLMResults *)allData
{
    @autoreleasepool {
        _isIndexing = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerWillBeginIndexing:currentState:)]) {
                [self.delegate managerWillBeginIndexing:self currentState:RBQQuadTreeIndexStateIndexing];
            }
        });
        
        RBQQuadTreeNodeObject *rootNode = [self rootNodeInRealm:realmIndex];
        
        [realmIndex beginWriteTransaction];
        
        NSUInteger index = 0;
        CGFloat floatCount = (float)allData.count;
        
        for (RBQQuadTreeDataObject *data in allData) {
            
            [self quadTreeNode:rootNode
                    insertData:data];
            
            index ++;
            
            CGFloat percentIndexed = (float)index/floatCount;
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                    
                    [self.delegate managerDidUpdate:self
                                       currentState:RBQQuadTreeIndexStateIndexing
                                     percentIndexed:percentIndexed];
                }
            });
            
            if (index % 1000 == 0) {
                NSLog(@"Index: %lu",(unsigned long)index);
            }
        }
        
        [realmIndex addOrUpdateObject:rootNode];
        
        [realmIndex commitWriteTransaction];
    
        // Update the number of points in the quad tree
        [self updatePropertiesPointsCountInRealm:realmIndex];
        
        // Update the state that we are finished
        [self updatePropertiesState:RBQQuadTreeIndexStateReady];
    
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:currentState:)]) {
                [self.delegate managerDidEndIndexing:self currentState:RBQQuadTreeIndexStateReady];
            }
        });
        
        _isIndexing = NO;
    }
}

- (void)updatePropertiesPointsCountInRealm:(RLMRealm *)realmIndex
{
    [realmIndex beginWriteTransaction];
    
    RBQQuadTreePropertiesObject *properties = [self currentQuadTreePropertiesInRealm:realmIndex];
    properties.totalInitialPoints = [RBQQuadTreeDataObject allObjectsInRealm:realmIndex].count;
    
    [realmIndex commitWriteTransaction];
}

// Must be called from a write transaction!
- (BOOL)quadTreeNode:(RBQQuadTreeNodeObject *)node
          insertData:(RBQQuadTreeDataObject *)data
{
    // Bail if our coordinate is not in the boundingBox
    if (!boundingBoxContainsData(node.boundingBox, data)) {
        return NO;
    }
    
    // Add the coordinate to the points array
    if (node.points.count < node.bucketCapacity) {
        
        // Sanity check to make sure we don't add duplicate points
        if ([node.points indexOfObject:data] == NSNotFound) {
            
            // Add data to the node
            [node.points addObject:data];
        }
        
        return YES;
    }
    
    // Check to see if the current node is a leaf, if it is, split
    if (!node.northWest) {
        [self quadTreeNodeSubdivide:node];
    }
    
    // Traverse the tree
    if ([self quadTreeNode:node.northWest insertData:data]) {
        return YES;
    }
    if ([self quadTreeNode:node.northEast insertData:data]) {
        return YES;
    }
    if ([self quadTreeNode:node.southWest insertData:data]) {
        return YES;
    }
    if ([self quadTreeNode:node.southEast insertData:data]) {
        return YES;
    }
    
    return NO;
}

// Must be called from a write transaction!
- (void)quadTreeNodeSubdivide:(RBQQuadTreeNodeObject *)node
{
    RBQBoundingBoxObject *box = node.boundingBox;
    
    double xMid = (box.width + box.x) / 2.0;
    double yMid = (box.height + box.y) / 2.0;
    
    RBQBoundingBoxObject *northWest = [RBQBoundingBoxObject createBoundingBoxWithX:box.x
                                                                                 y:box.y
                                                                             width:xMid
                                                                            height:yMid];
    
    node.northWest = [RBQQuadTreeNodeObject createQuadTreeNodeWithBox:northWest
                                                       bucketCapacity:node.bucketCapacity];
    
    RBQBoundingBoxObject *northEast = [RBQBoundingBoxObject createBoundingBoxWithX:xMid
                                                                                 y:box.y
                                                                             width:box.width
                                                                            height:yMid];
    
    node.northEast = [RBQQuadTreeNodeObject createQuadTreeNodeWithBox:northEast
                                                       bucketCapacity:node.bucketCapacity];
    
    RBQBoundingBoxObject *southWest = [RBQBoundingBoxObject createBoundingBoxWithX:box.x
                                                                                 y:yMid
                                                                             width:xMid
                                                                            height:box.height];
    
    node.southWest = [RBQQuadTreeNodeObject createQuadTreeNodeWithBox:southWest
                                                       bucketCapacity:node.bucketCapacity];
    
    RBQBoundingBoxObject *southEast = [RBQBoundingBoxObject createBoundingBoxWithX:xMid
                                                                                 y:yMid
                                                                             width:box.width
                                                                            height:box.height];
    
    node.southEast = [RBQQuadTreeNodeObject createQuadTreeNodeWithBox:southEast
                                                       bucketCapacity:node.bucketCapacity];
}

// This method is called after removing a RBQQuadTreeDataObject to rebalance the tree
- (void)balanceQuadTreeNode:(RBQQuadTreeNodeObject *)node
{
    if (node.northWest &&
        node.points.count < kRBQDefaultCapacity &&
        node.points.count > 0) {
        
        NSArray *childNodes = @[node.northWest,
                                node.northEast,
                                node.southWest,
                                node.southEast];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"points.count" ascending:NO];
        
        NSArray *sortedChildNodes = [childNodes sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        // Take a point from the first child (has the most points)
        RBQQuadTreeNodeObject *mostPointsNode = sortedChildNodes[0];
        
        if (mostPointsNode.points.count > 0) {
            RBQQuadTreeDataObject *data = [mostPointsNode.points firstObject];
            
            // Add it to the current node
            [node.points addObject:data];
            
            // Remove it from the child
            [mostPointsNode.points removeObjectAtIndex:0];
            
            // Now recurse the child
            [self balanceQuadTreeNode:mostPointsNode];
        }
    }
}

#pragma mark - Query Methods

- (void)quadTreeGatherDataWithRange:(RBQQuadTreeNodeObject *)node
                        boundingBox:(RBQBoundingBoxObject *)boundingBox
                    dataReturnBlock:(RBQDataReturnBlock)block
{
    if (!boundingBoxIntersectsBoundingBox(node.boundingBox,boundingBox)) {
        return;
    }
    
    for (RBQQuadTreeDataObject *data in node.points) {
        if (boundingBoxContainsData(boundingBox, data)) {
            block(data);
        }
    }
    
    if (!node.northWest) {
        return;
    }
    
    [self quadTreeGatherDataWithRange:node.northWest
                          boundingBox:boundingBox
                      dataReturnBlock:block];
    
    [self quadTreeGatherDataWithRange:node.northEast
                          boundingBox:boundingBox
                      dataReturnBlock:block];
    
    [self quadTreeGatherDataWithRange:node.southWest
                          boundingBox:boundingBox
                      dataReturnBlock:block];
    
    [self quadTreeGatherDataWithRange:node.southEast
                          boundingBox:boundingBox
                      dataReturnBlock:block];
}

#pragma mark - Helpers

- (RLMRealm *)currentRealmIndex
{
    return [self realmForEntityName:self.indexRequest.entityName];
}

- (RBQQuadTreeNodeObject *)currentRootNode
{
    return [self rootNodeInRealm:[self realmForEntityName:self.indexRequest.entityName]];
}

- (RBQQuadTreePropertiesObject *)currentQuadTreeProperties
{
    return [RBQQuadTreePropertiesObject objectInRealm:[self currentRealmIndex]
                                        forPrimaryKey:@(self.indexRequest.hash)];
}

- (RBQQuadTreePropertiesObject *)currentQuadTreePropertiesInRealm:(RLMRealm *)realm
{
    return [RBQQuadTreePropertiesObject objectInRealm:realm
                                        forPrimaryKey:@(self.indexRequest.hash)];
}

- (void)updatePropertiesState:(RBQQuadTreeIndexState)quadTreeIndexState
{
    RLMRealm *realmIndex = [self currentRealmIndex];
    
    [realmIndex beginWriteTransaction];
    
    RBQQuadTreePropertiesObject *properties = [self currentQuadTreeProperties];
    
    properties.quadTreeIndexState = quadTreeIndexState;
    
    [realmIndex commitWriteTransaction];
}

// Create Realm instance for entity name
- (RLMRealm *)realmForEntityName:(NSString *)EntityName
{
    return [RLMRealm realmWithPath:[self indexPathWithName:EntityName]];
}

//  Create a file path for Realm index with a given name
- (NSString *)indexPathWithName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error = nil;
    
    NSString *cachePath = [documentPath stringByAppendingPathComponent:@"/RBQQuadTreeManager/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.realm",name];
    
    cachePath = [cachePath stringByAppendingPathComponent:fileName];
    
    return cachePath;
}

- (RBQQuadTreeNodeObject *)rootNodeInRealm:(RLMRealm *)realm
{
    // Get the root node from Realm
    
    RBQQuadTreeNodeObject *rootNode = [RBQQuadTreeNodeObject objectInRealm:realm forPrimaryKey:[self rootNodePrimaryKey]];
    
    if (!rootNode) {
        RBQBoundingBoxObject *world = [RBQBoundingBoxObject createBoundingBoxWithX:kRBQRootNodeX
                                                                                 y:kRBQRootNodeY
                                                                             width:kRBQRootNodeWidth
                                                                            height:kRBQRootNodeHeight];
        
        
        rootNode = [RBQQuadTreeNodeObject createQuadTreeNodeWithBox:world
                                                     bucketCapacity:kRBQDefaultCapacity];
        rootNode.isRoot = YES;
        
        [realm beginWriteTransaction];
        
        [RBQBoundingBoxObject createOrUpdateInRealm:realm
                                         withObject:world];
        
        [RBQQuadTreeNodeObject createOrUpdateInRealm:realm
                                          withObject:rootNode];

        [realm commitWriteTransaction];
    }
    
    return rootNode;
}

- (NSString *)rootNodePrimaryKey
{
    return [NSString stringWithFormat:@"%f%f%f%f",
            kRBQRootNodeX,
            kRBQRootNodeY,
            kRBQRootNodeWidth,
            kRBQRootNodeHeight];
}


@end
