//
//  LocationDBManager.m
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "LocationDBManager.h"
#import "TBCoordinateQuadTree.h"
#import "TBQuadTree.h"

#import <Realm/Realm.h>

int kRBQDefaultCapacity = 4;

@interface LocationDBManager ()

@property (strong, nonatomic) RLMNotificationToken *notificationToken;

@end

@implementation LocationDBManager

+ (LocationDBManager *)defaultManager {
    static LocationDBManager *_defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultManager = [[self alloc] init];
    });
    return _defaultManager;
}

#pragma mark - Instance Methods

- (id)init {
    self = [super init];
    if (self) {
        [self registerNotification];
    }
    return self;
}

- (void)cleanUpRealm {
    /* Simply deleting all objects causes crash:
        ../tightdb/index_string.hpp:187: Assertion failed: Array::get_context_flag_from_header(alloc.translate(ref))
    
    DDLogInfo(@"Started Delete All DB Data");
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteAllObjects];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    DDLogInfo(@"Finished Delete All DB Data");
     */
}

- (void)registerNotification {
    self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *note, RLMRealm * realm) {
        // Check if we changed
        if ([note isEqualToString:RLMRealmDidChangeNotification]) {
            // Let's grab all of the
            if (realm.schema.objectSchema.count > 0) {
                
            }
        }
    }];
}

- (void)buildTreeInMemoryFirst {
    if ([self checkOnTree]) {
        [self createTreeInMemoryFirst];
    }
}

- (void)createTreeInMemoryFirst {
    [self createRootNode];
    DDLogInfo(@"Created Root Node");
    
    TBCoordinateQuadTree *coordinateQuadTree = [[TBCoordinateQuadTree alloc] init];
    
    DDLogInfo(@"Started Building Tree In Memory");
    [coordinateQuadTree buildTree];
    DDLogInfo(@"Finished Building Tree In Memory");
    
    __block NSUInteger nodeCount = 0;
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    DDLogInfo(@"Started Building Hotel DB");
    TBQuadTreeTraverse(coordinateQuadTree.root, ^(TBQuadTreeNode *currentNode) {
        nodeCount ++;
        
        if (nodeCount % 1000 == 0) {
            DDLogInfo(@"Processing Node:%li", (long)nodeCount);
        }
        
        // Create the bounding box
        double x = currentNode->boundingBox.x0;
        double y = currentNode->boundingBox.y0;
        double width = currentNode->boundingBox.xf;
        double height = currentNode->boundingBox.yf;
        
        BoundingBox *boundingBox = [BoundingBox createBoundingBoxWithX:x y:y width:width height:height];
        
        QuadTreeNode *node = [QuadTreeNode objectForPrimaryKey:boundingBox.key];
        
        // For the first node, we should create it, after that the items will be in Realm
        if (!node) {
            // Create the Realm node
            node = [QuadTreeNode createQuadTreeNodeWithBox:boundingBox bucketCapacity:currentNode->bucketCapacity];
            
            if (nodeCount == 1) {
                node.isRoot = YES;
            }
            
            // Add the node
            [[RLMRealm defaultRealm] addObject:node];
        }
        
        // Create the data points
        for (int i = 0; i < currentNode->count; i++) {
            TBQuadTreeNodeData data = currentNode->points[i];
            
            TBHotelInfo hotelInfo = *(TBHotelInfo *)data.data;
            
            NSString *hotelName = [NSString stringWithFormat:@"%s", hotelInfo.hotelName];
            NSString *hotelPhoneNumber = [NSString stringWithFormat:@"%s", hotelInfo.hotelPhoneNumber];
            NSString *Id = [NSString stringWithFormat:@"%@-%@",hotelName, hotelPhoneNumber];
            
            QuadTreeNodeData *nodeData = [QuadTreeNodeData createQuadTreeNodeDataWithLatitude:data.x
                                                                                    longitude:data.y
                                                                                           Id:Id
                                                                                   objectType:@""
                                                                                         name:hotelName];
            
            // Sanity check to make sure we don't add duplicate points
            if ([node.points indexOfObject:nodeData] == NSNotFound) {
                
                QuadTreeNodeData *addedData = [QuadTreeNodeData objectForPrimaryKey:nodeData.Id];
                if (!addedData) {
                    [node.points addObject:nodeData];
                }
                else {
                    [node.points addObject:addedData];
                }
            }
        }
        
        // Create the subnodes and their relationships
        if (currentNode->northWest) {
            BoundingBox *NWBoundingBox = [BoundingBox createBoundingBoxWithX:currentNode->northWest->boundingBox.x0
                                                                           y:currentNode->northWest->boundingBox.y0
                                                                       width:currentNode->northWest->boundingBox.xf
                                                                      height:currentNode->northWest->boundingBox.yf];
            
            // Create the Realm nodes
            QuadTreeNode *NWNode = [QuadTreeNode createQuadTreeNodeWithBox:NWBoundingBox
                                                            bucketCapacity:currentNode->bucketCapacity];
            
            if (NWNode) {
                node.northWest = NWNode;
            }
        }
        
        if (currentNode->northEast) {
            BoundingBox *NEBoundingBox = [BoundingBox createBoundingBoxWithX:currentNode->northEast->boundingBox.x0
                                                                           y:currentNode->northEast->boundingBox.y0
                                                                       width:currentNode->northEast->boundingBox.xf
                                                                      height:currentNode->northEast->boundingBox.yf];
            
            // Create the Realm nodes
            QuadTreeNode *NENode = [QuadTreeNode createQuadTreeNodeWithBox:NEBoundingBox
                                                            bucketCapacity:currentNode->bucketCapacity];
            
            if (NENode) {
                node.northEast = NENode;
            }
        }
        
        if (currentNode->southWest) {
            BoundingBox *SWBoundingBox = [BoundingBox createBoundingBoxWithX:currentNode->southWest->boundingBox.x0
                                                                           y:currentNode->southWest->boundingBox.y0
                                                                       width:currentNode->southWest->boundingBox.xf
                                                                      height:currentNode->southWest->boundingBox.yf];
            
            // Create the Realm nodes
            QuadTreeNode *SWNode = [QuadTreeNode createQuadTreeNodeWithBox:SWBoundingBox
                                                            bucketCapacity:currentNode->bucketCapacity];
            
            if (SWNode) {
                node.southWest = SWNode;
            }
        }
        
        if (currentNode->southWest) {
            BoundingBox *SEBoundingBox = [BoundingBox createBoundingBoxWithX:currentNode->southEast->boundingBox.x0
                                                                           y:currentNode->southEast->boundingBox.y0
                                                                       width:currentNode->southEast->boundingBox.xf
                                                                      height:currentNode->southEast->boundingBox.yf];
            
            // Create the Realm nodes
            QuadTreeNode *SENode = [QuadTreeNode createQuadTreeNodeWithBox:SEBoundingBox
                                                            bucketCapacity:currentNode->bucketCapacity];
            
            if (SENode) {
                node.southEast = SENode;
            }
        }
    });
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    DDLogInfo(@"Finished Building Hotel DB");
    
    self.treeBuilt = YES;
}

// INITIAL ATTEMPT TO BUILD TREE INTO REALM DIRECTLY--> MEMORY CRASH

- (void)buildTreeDirectlyInRealm {
    if ([self checkOnTree]) {
        [self createTreeDirectlyInRealm];
    }
}

- (void)createTreeDirectlyInRealm {
    [self createRootNode];
    DDLogInfo(@"Created Root Node");
    
    NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"USA-HotelMotel" ofType:@"csv"] encoding:NSASCIIStringEncoding error:nil];
    NSArray *lines = [data componentsSeparatedByString:@"\n"];
    
    // Get the root node from Realm
    RLMResults *rootNode = [QuadTreeNode objectsWhere:@"isRoot == YES"];
    
    if (rootNode.count == 1) {
        rootNode = nil;
        
        // Break up the writing blocks into smaller portions
        // by starting a new transaction
        NSInteger batchSize = 1000;
        NSInteger totalBatches = lines.count % batchSize ? lines.count/batchSize + 1 : lines.count/batchSize;
        
        DDLogInfo(@"Started Building Hotel DB");
        DDLogInfo(@"Total Batches:%li", (long)totalBatches);
        DDLogInfo(@"Batch Size:%li", (long)batchSize);
        
        for (NSInteger idx1 = 0; idx1 < totalBatches; idx1++) {
            rootNode = nil;
            
            rootNode = [QuadTreeNode objectsWhere:@"isRoot == YES"];
            
            QuadTreeNode *root = [rootNode firstObject];
            
            NSUInteger startPoint = idx1 * batchSize;
            NSUInteger length = batchSize < lines.count - idx1 * batchSize ? batchSize : lines.count - idx1 * batchSize;
            
            NSArray *subArray = [lines subarrayWithRange:NSMakeRange(startPoint,length)];
            
            DDLogInfo(@"Processing Batch:%li", (long)idx1);
            
            [[RLMRealm defaultRealm] beginWriteTransaction];
            
            // Add row via dictionary. Property order is ignored.
            for (NSString *line in subArray) {
                QuadTreeNodeData *data = [self dataFromLine:line];
                [self quadTreeNode:root insertData:data];
            }
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
        }
        DDLogInfo(@"Finished Building Hotel DB");
    }
    
    self.treeBuilt = YES;
}

- (void)quadTreeBuildWithData:(NSArray *)data {
    
    // Get the root node from Realm
    RLMResults *rootNode = [QuadTreeNode objectsWhere:@"isRoot == YES"];
    
    if (rootNode.count == 1) {
        QuadTreeNode *root = [rootNode firstObject];
        
        // Break up the writing blocks into smaller portions
        // by starting a new transaction
        NSInteger batchSize = 1000;
        NSInteger totalBatches = data.count % batchSize ? data.count/batchSize + 1 : data.count/batchSize;
        
        for (NSInteger idx1 = 0; idx1 < totalBatches; idx1++) {
            NSUInteger startPoint = idx1 * batchSize;
            NSUInteger length = batchSize < data.count - idx1 * batchSize ? batchSize : data.count - idx1 * batchSize;
            
            NSArray *subArray = [data subarrayWithRange:NSMakeRange(startPoint,length)];
            
            DDLogInfo(@"Processing Batch:%li", (long)idx1);
            
            [[RLMRealm defaultRealm] beginWriteTransaction];
            
            // Add row via dictionary. Property order is ignored.
            for (QuadTreeNodeData *nodeData in subArray) {
                [self quadTreeNode:root insertData:nodeData];
            }
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
        }
    }
}

- (QuadTreeNodeData *)dataFromLine:(NSString *)line {
    NSArray *components = [line componentsSeparatedByString:@","];
    double latitude = [components[1] doubleValue];
    double longitude = [components[0] doubleValue];
    
    NSString *hotelName = [components[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *hotelPhoneNumber = [[components lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *Id = [NSString stringWithFormat:@"%@-%@",hotelName, hotelPhoneNumber];
    return [QuadTreeNodeData createQuadTreeNodeDataWithLatitude:latitude
                                                      longitude:longitude
                                                             Id:Id
                                                     objectType:@""
                                                           name:hotelName];
}

- (BOOL)checkOnTree {
    if (self.treeBuilt) {
        // Show Alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tree Already Built"
                                                        message:@"Click View Map To See Query Capabilities"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Getters

- (void)createRootNode {
    // Get the root node from Realm
    RLMResults *rootNode = [QuadTreeNode objectsWhere:@"isRoot == YES"];
    
    if (rootNode.count == 0) {
        BoundingBox *world = [BoundingBox createBoundingBoxWithX:19
                                                               y:-166
                                                           width:72
                                                          height:-53];
        
        QuadTreeNode *initialNode = [QuadTreeNode createQuadTreeNodeWithBox:world
                                                             bucketCapacity:kRBQDefaultCapacity];
        initialNode.isRoot = YES;
        
        [[RLMRealm defaultRealm] beginWriteTransaction];
        [BoundingBox createOrUpdateInDefaultRealmWithObject:world];
        [QuadTreeNode createOrUpdateInDefaultRealmWithObject:initialNode];
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }
}

#pragma mark - Bounding Box Functions

- (BOOL)boundingBox:(BoundingBox *)box containsData:(QuadTreeNodeData *)data {
    
    BOOL containsX = box.x <= data.latitude && data.latitude <= box.width;
    BOOL containsY = box.y <= data.longitude && data.longitude <= box.height;
    
    return containsX && containsY;
}

- (BOOL)boundingBox:(BoundingBox *)b1 intersectsBoundingBox:(BoundingBox *)b2 {
    
    return (b1.x <= b2.width && b1.width >= b2.x && b1.y <= b2.height && b1.height >= b2.y);
}

#pragma mark - Quad Tree Functions

- (void)quadTreeNodeSubdivide:(QuadTreeNode *)node {
//    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    BoundingBox *box = node.boundingBox;
    
    double xMid = (box.width + box.x) / 2.0;
    double yMid = (box.height + box.y) / 2.0;
    
    BoundingBox *northWest = [BoundingBox createBoundingBoxWithX:box.x
                                                               y:box.y
                                                           width:xMid
                                                          height:yMid];
    
    node.northWest = [QuadTreeNode createQuadTreeNodeWithBox:northWest
                                              bucketCapacity:node.bucketCapacity];
    
    BoundingBox *northEast = [BoundingBox createBoundingBoxWithX:xMid
                                                               y:box.y
                                                           width:box.width
                                                          height:yMid];
    
    node.northEast = [QuadTreeNode createQuadTreeNodeWithBox:northEast
                                              bucketCapacity:node.bucketCapacity];
    
    BoundingBox *southWest = [BoundingBox createBoundingBoxWithX:box.x
                                                               y:yMid
                                                           width:xMid
                                                          height:box.height];
    
    node.southWest = [QuadTreeNode createQuadTreeNodeWithBox:southWest
                                              bucketCapacity:node.bucketCapacity];
    
    BoundingBox *southEast = [BoundingBox createBoundingBoxWithX:xMid
                                                               y:yMid
                                                           width:box.width
                                                          height:box.height];
    
    node.southEast = [QuadTreeNode createQuadTreeNodeWithBox:southEast
                                              bucketCapacity:node.bucketCapacity];
    
//    [[RLMRealm defaultRealm] commitWriteTransaction];
}

- (BOOL)quadTreeNode:(QuadTreeNode *)node insertData:(QuadTreeNodeData *)data {
    
    // Bail if our coordinate is not in the boundingBox
    if (![self boundingBox:node.boundingBox containsData:data]) {
        return NO;
    }
    
    // Add the coordinate to the points array
    if (node.points.count < node.bucketCapacity) {
//        [[RLMRealm defaultRealm] beginWriteTransaction];
        
        // Sanity check to make sure we don't add duplicate points
        if ([node.points indexOfObject:data] == NSNotFound) {
            
            QuadTreeNodeData *addedData = [QuadTreeNodeData objectForPrimaryKey:data.Id];
            if (!addedData) {
                [node.points addObject:data];
            }
            else {
                [node.points addObject:addedData];
            }
        }
        
//        [[RLMRealm defaultRealm] commitWriteTransaction];

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

- (void)quadTreeGatherData:(QuadTreeNode *)node
                     range:(BoundingBox *)range
           completionBlock:(DataReturnBlock)block {
    
    if (![self boundingBox:node.boundingBox intersectsBoundingBox:range]) {
        return;
    }
    
//    for (int i = 0; i < node.count; i++) {
    for (QuadTreeNodeData *data in node.points) {
        if ([self boundingBox:range containsData:data]) {
            block(data);
        }
    }
    
    if (!node.northWest) {
        return;
    }
    
    [self quadTreeGatherData:node.northWest
                       range:range
             completionBlock:block];
    
    [self quadTreeGatherData:node.northEast
                       range:range
             completionBlock:block];
    
    [self quadTreeGatherData:node.southWest
                       range:range
             completionBlock:block];
    
    [self quadTreeGatherData:node.southEast
                       range:range
             completionBlock:block];
}

- (void)quadTreeTraverse:(QuadTreeNode *)node completionBlock:(QuadTreeTraverseBlock)block {
    
    block(node);
    
    if (!node.northWest) {
        return;
    }
    
    [self quadTreeTraverse:node.northWest
           completionBlock:block];
    
    [self quadTreeTraverse:node.northEast
           completionBlock:block];
    
    [self quadTreeTraverse:node.southWest
           completionBlock:block];
    
    [self quadTreeTraverse:node.southEast
           completionBlock:block];
}

- (QuadTreeNode *)parentNodeForNode:(QuadTreeNodeData *)data {
    
    NSArray *owners = [data linkingObjectsOfClass:@"QuadTreeNode" forProperty:@"points"];
    
#ifdef DEBUG
    // Incorrect object class for toolbarItem
    NSAssert(owners.count <= 1, @"QuadTreeNodeData should only have 1 parentNode");
#endif
    
    if (owners.count == 1) {
        return [owners firstObject];
    }
    
    return  nil;
}

@end
