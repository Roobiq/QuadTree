//
//  RBQQuadTreeIndexObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreeIndexObject.h"

#pragma mark - Constants
double kRBQPercentChangeUntilReindex = 0.2;
int kRBQDefaultCapacity = 100;

// Based off of MKMapRectWorld Constant
double kRBQRootNodeX = -85.051128779806603;
double kRBQRootNodeY = -180;
double kRBQRootNodeWidth = 85.051128779806589;
double kRBQRootNodeHeight = 180;

#pragma mark - Public Functions

NSString * RBQStringFromQuadTreeIndexState(RBQQuadTreeIndexState state) {
    switch (state) {
        case RBQQuadTreeIndexStateIndexing:
            return @"Indexing";
        case RBQQuadTreeIndexStateReady:
            return @"Ready";
        case RBQQuadTreeIndexStateNoData:
            return @"Index Empty";
        default:
            return nil;
    }
}

@interface RBQQuadTreeIndexObject ()

@property (nonatomic, strong) dispatch_queue_t indexObjectQueue;

@end

@implementation RBQQuadTreeIndexObject
@synthesize rootNode = _rootNode;

#pragma mark - Public Class

+ (instancetype)createQuadTreeIndexWithIndexRequest:(RBQIndexRequest *)indexRequest
{
    RBQQuadTreeIndexObject *index = [[RBQQuadTreeIndexObject alloc] init];
    index->_allPoints = [[RBQSafeMutableSet alloc] init];
    index->_key = (NSInteger)indexRequest.hash;
    index->_totalInitialPoints = 0;
    index->_indexObjectQueue = dispatch_queue_create("com.Roobiq.RBQQuadTreeIndexObject.indexObjectQueue",
                                                     DISPATCH_QUEUE_CONCURRENT);
    
    return index;
}

#pragma mark - Public Instance

- (RBQQuadTreeDataObject *)dataForObject:(RLMObject *)object
{
    // Convert to a safe object because look up calls isEqual/hash methods which are on base class
    RBQSafeRealmObject *safeObject = [RBQSafeRealmObject safeObjectFromObject:object];
    
    return [self.allPoints member:safeObject];
}

- (RBQQuadTreeDataObject *)dataForSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [self.allPoints member:safeObject];
}

- (void)insertAndIndexData:(RBQQuadTreeDataObject *)data
{
//    dispatch_sync(self.indexObjectQueue, ^(){
        [self.allPoints addObject:data];
        
        [self quadTreeNode:self.rootNode
                insertData:data];
        
        self.totalInitialPoints ++;
//    });
}

- (void)removeData:(RBQQuadTreeDataObject *)data
{
//    dispatch_sync(self.indexObjectQueue, ^(){
        [data.node.points removeObject:data];
        
        [self.allPoints removeObject:data];
//    });
}

- (void)resetIndex
{
//    dispatch_barrier_sync(self.indexObjectQueue, ^(){
        @autoreleasepool {
            self->_rootNode = nil;
        }
//    });
}

- (void)resetDataAndIndex
{
//    dispatch_barrier_sync(self.indexObjectQueue, ^(){
        @autoreleasepool {
            self->_allPoints = [[RBQSafeMutableSet alloc] init];
            self->_rootNode = nil;
        }
//    });
}

- (BOOL)needsIndexingIfDeleteCount:(NSUInteger)deleteCount
{
    NSUInteger currentTotal = self.allPoints.count;
    
    return (currentTotal - deleteCount) < (self.totalInitialPoints * (1 - kRBQPercentChangeUntilReindex));
}

#pragma mark - Getters

- (RBQQuadTreeNodeObject *)rootNode
{
    if (!_rootNode) {
        RBQBoundingBoxObject *world = [RBQBoundingBoxObject createBoundingBoxWithX:kRBQRootNodeX
                                                                                 y:kRBQRootNodeY
                                                                             width:kRBQRootNodeWidth
                                                                            height:kRBQRootNodeHeight];
        
        _rootNode = [RBQQuadTreeNodeObject createQuadTreeNodeWithBox:world bucketCapacity:kRBQDefaultCapacity];
    }
    
    return _rootNode;
}

- (RBQQuadTreeIndexState)indexState
{
    if (self.allPoints.count == 0) {
        return RBQQuadTreeIndexStateNoData;
    }
    
    return _indexState;
}

#pragma mark - Private

- (BOOL)quadTreeNode:(RBQQuadTreeNodeObject *)node
          insertData:(RBQQuadTreeDataObject *)data
{
    // Bail if our coordinate is not in the boundingBox
    if (!boundingBoxContainsData(node.boundingBox, data)) {
        return NO;
    }
    
    // Add the coordinate to the points array
    if (node.points.count < node.bucketCapacity) {
        
        // Add data to the node
        [node.points addObject:data];
        
        data.node = node;
        
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

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQQuadTreeIndexObject *index = [[RBQQuadTreeIndexObject allocWithZone:zone] init];
    index->_key = self.key;
    index->_rootNode = self.rootNode;
    index->_indexState = self.indexState;
    index->_totalInitialPoints = self.totalInitialPoints;
    index->_allPoints = self.allPoints;
    
    return index;
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self->_key = [decoder decodeIntegerForKey:@"key"];
        self->_rootNode = [decoder decodeObjectForKey:@"rootNode"];
        self->_indexState = [decoder decodeIntegerForKey:@"indexState"];
        self->_totalInitialPoints = [decoder decodeIntegerForKey:@"totalInitialPoints"];
        self->_allPoints = [decoder decodeObjectForKey:@"allPoints"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.key forKey:@"key"];
    [encoder encodeObject:self.rootNode forKey:@"rootNode"];
    [encoder encodeInteger:self.indexState forKey:@"indexState"];
    [encoder encodeInteger:self.totalInitialPoints forKey:@"totalInitialPoints"];
    [encoder encodeObject:self.allPoints forKey:@"allPoints"];
}

@end
