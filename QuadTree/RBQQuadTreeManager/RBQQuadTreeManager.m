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
#import "RBQClusterAnnotation.h"

#import <MapKit/MapKit.h>

@class RBQNodeInternal;

#pragma mark - Constants

int kRBQMaxCountUntilFulLWipe = 10000;

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

NSInteger RBQZoomScaleToZoomLevel(MKZoomScale scale)
{
    double totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0;
    NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
    NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom + floor(log2f(scale) + 0.5));
    
    return zoomLevel;
}

float RBQCellSizeForZoomScale(MKZoomScale zoomScale)
{
    NSInteger zoomLevel = RBQZoomScaleToZoomLevel(zoomScale);
    
    switch (zoomLevel) {
        case 13:
        case 14:
        case 15:
            return 64;
        case 16:
        case 17:
        case 18:
            return 32;
        case 19:
            return 16;
            
        default:
            return 88;
    }
}

#pragma mark - RBQQuadTreeManager

@interface RBQQuadTreeManager ()

@property (nonatomic, strong) dispatch_queue_t indexQueue;

@property (nonatomic, strong) RBQNotificationToken *notificationToken;

@property (nonatomic, strong) RBQQuadTreeIndexObject *index;

@end

@implementation RBQQuadTreeManager
@synthesize isIndexing = _isIndexing,
indexRequest = _indexRequest;

#pragma mark - Constructors

- (id)init
{
    self = [super init];
    
    if (self) {
        _indexQueue = dispatch_queue_create("com.Roobiq.RBQQuadTreeManager.indexQueue",
                                            DISPATCH_QUEUE_CONCURRENT);
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
        manager->_index = [RBQQuadTreeIndexObject createQuadTreeIndexWithIndexRequest:indexRequest];
        
        // Add the manager to the cache
        @synchronized(entityNameToManagerMap) {
            [entityNameToManagerMap setObject:manager forKey:indexRequest.entityName];
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
    dispatch_async(manager.indexQueue, ^(){
        
        RLMRealm *realm = manager.indexRequest.realm;
        
        NSUInteger mainDataCount =
        [NSClassFromString(manager.indexRequest.entityName) allObjectsInRealm:realm].count;
        
        NSUInteger dataCount = manager.index.allPoints.count;
        
        // The indexing was interrupted, restart it
        if (manager.index.indexState == RBQQuadTreeIndexStateIndexing) {
            
            [manager rebuildIndex];
        }
        // The loading of data failed to complete, restart it from scratch and then index
        else if (dataCount != mainDataCount) {
            
            [manager resetDataAndRebuildIndex];
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
    [self insertObjects:@[object]];
}

- (void)insertObjects:(id<NSFastEnumeration>)objects
{
    dispatch_group_t taskGroup = dispatch_group_create();
    
    NSUInteger count = 0;
    NSUInteger total = (NSUInteger)[(NSObject *)objects valueForKey:@"count"];
    
    for (RLMObject *object in objects) {
        
        NSString *className = [RLMObject classNameForObject:object];
        NSAssert([className isEqualToString:self.indexRequest.entityName], @"RLMObject in collection does not match the registered class for the manager's RBQIndexRequest");
        
        count ++;
        
        if (count % 1000 == 0) {
            NSLog(@"Indexed: %lu",(unsigned long)count);
        }
        
        RBQQuadTreeDataObject *data =
        [RBQQuadTreeDataObject createQuadTreeDataObjectWithObject:object
                                                  latitudeKeyPath:self.indexRequest.latitudeKeyPath
                                                 longitudeKeyPath:self.indexRequest.longitudeKeyPath];
        
        
//        dispatch_group_async(taskGroup, self.indexQueue, ^{
            [self.index insertAndIndexData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                    
                    CGFloat percentIndexed = (CGFloat)count/(CGFloat)total;
                    NSLog(@"Percent Indexed: %f",percentIndexed);
                    
                    [self.delegate managerDidUpdate:self
                                       currentState:RBQQuadTreeIndexStateIndexing
                                     percentIndexed:percentIndexed];
                }
            });
//        });
    }
    
    // Submit block to run on the completion of all other blocks in the queue
//    dispatch_group_notify(taskGroup, self.indexQueue, ^{
        // Update the state that we are finished
        [self updatePropertiesState:RBQQuadTreeIndexStateReady];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:currentState:)]) {
                [self.delegate managerDidEndIndexing:self currentState:RBQQuadTreeIndexStateReady];
            }
        });
//    });
}

- (void)removeObject:(RLMObject *)object
{
    [self removeObjects:@[object]];
}

- (void)removeObjects:(id<NSFastEnumeration>)objects
{
    NSUInteger total = (NSUInteger)[(NSObject *)objects valueForKey:@"count"];
    
    if ([self.index needsIndexingIfDeleteCount:total]) {
        
    }
    else {
        for (RLMObject *object in objects) {
            
            NSString *className = [RLMObject classNameForObject:object];
            NSAssert([className isEqualToString:self.indexRequest.entityName], @"RLMObject in collection does not match the registered class for the manager's RBQIndexRequest");
            
            RBQQuadTreeDataObject *data = [self.index dataForObject:object];
            
            [self.index removeData:data];
        }
    }
}

- (void)retrieveDataInMapRect:(MKMapRect)mapRect
              dataReturnBlock:(RBQDataReturnBlock)block
{
    RBQQuadTreeNodeObject *rootNode = self.index.rootNode;
    RBQBoundingBoxObject *boundingBox = boundingBoxForMapRect(mapRect);
    
    [self quadTreeGatherDataWithRange:rootNode
                          boundingBox:boundingBox
                      dataReturnBlock:block];
}

- (NSSet *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect
                               withZoomScale:(MKZoomScale)zoomScale
                                titleKeyPath:(NSString *)titleKeyPath
                             subTitleKeyPath:(NSString *)subTitleKeyPath
{
    double RBQCellSize = RBQCellSizeForZoomScale(zoomScale);
    double scaleFactor = zoomScale / RBQCellSize;
    
    NSInteger minX = floor(MKMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(MKMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(MKMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(MKMapRectGetMaxY(rect) * scaleFactor);
    
    NSMutableSet *clusteredAnnotations = [[NSMutableSet alloc] init];
    for (NSInteger x = minX; x <= maxX; x++) {
        for (NSInteger y = minY; y <= maxY; y++) {
            MKMapRect mapRect = MKMapRectMake(x / scaleFactor, y / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor);
            
            __block double totalLat = 0;
            __block double totalLon = 0;
            __block int count = 0;
            
            RBQClusterAnnotation *annotation = [[RBQClusterAnnotation alloc] initWithTitleKeyPath:titleKeyPath
                                                                                  subTitleKeyPath:subTitleKeyPath];
            
            [self retrieveDataInMapRect:mapRect dataReturnBlock:^(RBQQuadTreeDataObject *data) {
                totalLat += data.latitude;
                totalLon += data.longitude;
                count++;
                
                [annotation addSafeObjectToCluster:data];
            }];
            
            if (count == 1) {
                annotation.coordinate = CLLocationCoordinate2DMake(totalLat, totalLon);
            }
            else if (count > 1) {
                annotation.coordinate = CLLocationCoordinate2DMake(totalLat / count, totalLon / count);
            }
            
            [clusteredAnnotations addObject:annotation];
        }
    }
    
    return clusteredAnnotations.copy;
}

- (void)displayAnnotations:(NSSet *)annotations onMapView:(MKMapView *)mapView
{
    NSMutableSet *before = [NSMutableSet setWithArray:mapView.annotations];
    [before removeObject:[mapView userLocation]];
    NSSet *after = [NSSet setWithSet:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [mapView addAnnotations:[toAdd allObjects]];
        [mapView removeAnnotations:[toRemove allObjects]];
    }];
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
            
            dispatch_async(self.indexQueue, ^(){
                // Gather up all of the safe objects that will be indexed
                NSSet *allSafeObjectsToIndex = [entityChangesObject.addedSafeObjects setByAddingObjectsFromSet:entityChangesObject.changedSafeObjects];
                
                if (allSafeObjectsToIndex.count > 0) {
                    [self insertSafeObjects:allSafeObjectsToIndex];
                }
                
                if (entityChangesObject.deletedSafeObjects.count > 0) {
                    [self removeSafeObjects:entityChangesObject.deletedSafeObjects];
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

- (void)rebuildIndex
{
    dispatch_async(self.indexQueue, ^(){
        NSSet *oldData = self.index.allPoints.copy;
        
        [self.index resetDataAndIndex];
        
        dispatch_group_t taskGroup = dispatch_group_create();
        
        NSUInteger count = 0;
        NSUInteger total = oldData.count;
        
        for (RBQQuadTreeDataObject *data in oldData) {
            count ++;
            
            if (count % 1000 == 0) {
                NSLog(@"Indexed: %lu",(unsigned long)count);
            }

//            dispatch_group_async(taskGroup, self.indexQueue, ^{
                [self.index insertAndIndexData:data];
                
                dispatch_async(dispatch_get_main_queue(), ^(){
                    if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                        
                        CGFloat percentIndexed = (CGFloat)count/(CGFloat)total;
                        NSLog(@"Percent Indexed: %f",percentIndexed);
                        
                        [self.delegate managerDidUpdate:self
                                           currentState:RBQQuadTreeIndexStateIndexing
                                         percentIndexed:percentIndexed];
                    }
                });
//            });
        }
        
        // Submit block to run on the completion of all other blocks in the queue
//        dispatch_group_notify(taskGroup, self.indexQueue, ^{
            // Update the state that we are finished
            [self updatePropertiesState:RBQQuadTreeIndexStateReady];
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:currentState:)]) {
                    [self.delegate managerDidEndIndexing:self currentState:RBQQuadTreeIndexStateReady];
                }
            });
//        });
    });
}
             
- (void)resetDataAndRebuildIndex
{
    dispatch_async(self.indexQueue, ^(){
        [self.index resetDataAndIndex];
         
        RLMResults *allData = [NSClassFromString(self.indexRequest.entityName) allObjectsInRealm:self.indexRequest.realm];
         
        [self insertObjects:allData];
    });
}

- (void)insertSafeObjects:(NSSet *)safeObjects
{
    dispatch_group_t taskGroup = dispatch_group_create();
    
    NSUInteger count = 0;
    NSUInteger total = safeObjects.count;
    
    for (RBQSafeRealmObject *safeObject in safeObjects) {
        
        count ++;
        
        if (count % 1000 == 0) {
            NSLog(@"Indexed: %lu",(unsigned long)count);
        }
        
        RBQQuadTreeDataObject *data =
        [RBQQuadTreeDataObject createQuadTreeDataObjectWithSafeObject:safeObject
                                                      latitudeKeyPath:self.indexRequest.latitudeKeyPath
                                                     longitudeKeyPath:self.indexRequest.longitudeKeyPath];
        
        
//        dispatch_group_async(taskGroup, self.indexQueue, ^{
            [self.index insertAndIndexData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([self.delegate respondsToSelector:@selector(managerDidUpdate:currentState:percentIndexed:)]) {
                    
                    CGFloat percentIndexed = (CGFloat)count/(CGFloat)total;
                    
                    [self.delegate managerDidUpdate:self
                                       currentState:RBQQuadTreeIndexStateIndexing
                                     percentIndexed:percentIndexed];
                }
            });
//        });
    }
    
    // Submit block to run on the completion of all other blocks in the queue
//    dispatch_group_notify(taskGroup, self.indexQueue, ^{
        // Update the state that we are finished
        [self updatePropertiesState:RBQQuadTreeIndexStateReady];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if ([self.delegate respondsToSelector:@selector(managerDidEndIndexing:currentState:)]) {
                [self.delegate managerDidEndIndexing:self currentState:RBQQuadTreeIndexStateReady];
            }
        });
//    });
}

- (void)removeSafeObjects:(NSSet *)safeObjects
{
    NSUInteger total = safeObjects.count;
    
    if ([self.index needsIndexingIfDeleteCount:total]) {
        dispatch_async(self.indexQueue, ^(){
            [self.index resetDataAndIndex];
            
            RLMResults *allData = [NSClassFromString(self.indexRequest.entityName) allObjectsInRealm:self.indexRequest.realm];
            
            [self insertObjects:allData];
        });
    }
    else {
        for (RBQSafeRealmObject *safeObject in safeObjects) {
            
            RBQQuadTreeDataObject *data = [self.index dataForSafeObject:safeObject];
            
            [self.index removeData:data];
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

- (void)updatePropertiesState:(RBQQuadTreeIndexState)indexState
{
    self.index.indexState = indexState;
}

- (void)archiveIndexToDisk:(RBQQuadTreeIndexObject *)index
              indexRequest:(RBQIndexRequest *)indexRequest
{
    [NSKeyedArchiver archiveRootObject:index toFile:[self indexPathWithName:indexRequest.entityName]];
}

- (RBQQuadTreeIndexObject *)unarchiveIndexWithIndexRequest:(RBQIndexRequest *)indexRequest
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self indexPathWithName:indexRequest.entityName]];
}

//  Create a file path for index with a given name
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
    
    NSString *fileName = [NSString stringWithFormat:@"%@.indexCache",name];
    
    cachePath = [cachePath stringByAppendingPathComponent:fileName];
    
    return cachePath;
}


@end
