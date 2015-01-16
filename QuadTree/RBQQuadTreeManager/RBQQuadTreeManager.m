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
#import "RBQQuadTreePropertiesObject.h"

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
    
//    if (!manager.notificationToken) {
    [manager registerNotifications];
//    }
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
        
        NSSet *safeObjects = [self addOrUpdateObjectsInIndexAndReturnSafeObjects:@[object]];
        
        [self indexSafeObjects:safeObjects];
    }
}

- (void)insertObjects:(id<NSFastEnumeration>)objects
{
    NSSet *safeObjects = [self addOrUpdateObjectsInIndexAndReturnSafeObjects:objects];
    
    [self indexSafeObjects:safeObjects];
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
            
            // Gather up all of the safe objects that will be indexed
            NSSet *allSafeObjectsToIndex = [entityChangesObject.addedSafeObjects setByAddingObjectsFromSet:entityChangesObject.changedSafeObjects];
            
            if (allSafeObjectsToIndex.count > 0) {
                [self addOrUpdateSafeObjectsInIndex:allSafeObjectsToIndex];
                
                [self indexSafeObjects:allSafeObjectsToIndex];
            }
            
            if (entityChangesObject.deletedSafeObjects.count > 0) {
                [self deleteObjectsWithSafeObjectsInIndex:entityChangesObject.deletedSafeObjects];
            }
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
{
    @autoreleasepool {
        NSMutableSet *safeObjects = [[NSMutableSet alloc] init];
        
        RLMRealm *realmIndex = [self currentRealmIndex];
        
        NSLog(@"Started Writing Objects To Index");
        
        [realmIndex beginWriteTransaction];
        
        for (RLMObject *object in objects) {
            
            RBQQuadTreeDataObject *data =
            [RBQQuadTreeDataObject createQuadTreeDataObjectWithObject:object
                                                      latitudeKeyPath:self.indexRequest.latitudeKeyPath
                                                     longitudeKeyPath:self.indexRequest.longitudeKeyPath];
            
            [realmIndex addOrUpdateObject:data];
            
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
        RLMRealm *realmIndex = [self currentRealmIndex];
        
        NSLog(@"Started Writing Objects To Index");
        
        [realmIndex beginWriteTransaction];
        
        for (RBQSafeRealmObject *object in safeObjects) {
            
            RBQQuadTreeDataObject *data =
            [RBQQuadTreeDataObject createQuadTreeDataObjectWithSafeObject:object
                                                          latitudeKeyPath:self.indexRequest.latitudeKeyPath
                                                         longitudeKeyPath:self.indexRequest.longitudeKeyPath];
            
            [realmIndex addOrUpdateObject:data];
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
{
    dispatch_async(self.serialIndexQueue, ^(){
        NSLog(@"Started Building Quad Tree");
        
        // If we have a lot of safe objects, then clear index and start from scratch
        if (safeObjects.count > kRBQMaxCountUntilFulLWipe) {
            [self clearIndex];
        }
    
        [self performIndexingWithSafeObjects:safeObjects];
        
        NSLog(@"Finished Building Quad Tree");
    });
}

- (void)rebuildIndex
{
    dispatch_async(self.serialIndexQueue, ^(){
        NSLog(@"Started Re-building Quad Tree");
        
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
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerWillBeginIndexing:)]) {
                [self.delegate managerWillBeginIndexing:self];
            }
        });
        
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
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(manager:percentIndexedUpdated:)]) {
                    
                    CGFloat percentIndexed = (float)index/(float)safeObjects.count;
                    
                    [self.delegate manager:self percentIndexedUpdated:percentIndexed];
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
    
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:)]) {
                [self.delegate managerDidEndIndexing:self];
            }
        });
        
        _isIndexing = NO;
    }
}

- (void)performIndexingInRealm:(RLMRealm *)realmIndex
                   withAllData:(RLMResults *)allData
{
    @autoreleasepool {
        _isIndexing = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerWillBeginIndexing:)]) {
                [self.delegate managerWillBeginIndexing:self];
            }
        });
        
        RBQQuadTreeNodeObject *rootNode = [self rootNodeInRealm:realmIndex];
        
        [realmIndex beginWriteTransaction];
        
        NSUInteger index = 0;
        
        for (RBQQuadTreeDataObject *data in allData) {
            
            [self quadTreeNode:rootNode
                    insertData:data];
            
            index ++;
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(manager:percentIndexedUpdated:)]) {
                    
                    CGFloat percentIndexed = (float)index/(float)allData.count;
                    
                    [self.delegate manager:self percentIndexedUpdated:percentIndexed];
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
    
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:)]) {
                [self.delegate managerDidEndIndexing:self];
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
