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

+ (LocationDBManager *)defaultManager
{
    static LocationDBManager *_defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultManager = [[self alloc] init];
    });
    return _defaultManager;
}

#pragma mark - Instance Methods

- (id)init
{
    self = [super init];
    if (self) {
        [self registerNotification];
    }
    return self;
}

- (void)cleanUpRealm
{
    /* Simply deleting all objects causes crash:
        ../tightdb/index_string.hpp:187: Assertion failed: Array::get_context_flag_from_header(alloc.translate(ref))
    
    DDLogInfo(@"Started Delete All DB Data");
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteAllObjects];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    DDLogInfo(@"Finished Delete All DB Data");
     */
}

- (void)registerNotification
{
    self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *note, RLMRealm * realm) {
        // Check if we changed
        if ([note isEqualToString:RLMRealmDidChangeNotification]) {
            // Let's grab all of the
            if (realm.schema.objectSchema.count > 0) {
                
            }
        }
    }];
}

- (void)buildTreeInMemoryFirst
{
    if ([self checkOnTree]) {
        [self createTreeInMemoryFirst];
    }
}

- (void)createTreeInMemoryFirst
{
    [self createRootNode];
    DDLogInfo(@"Created Root Node");
    
    @autoreleasepool {
        // Build the quadTree in memory
        DDLogInfo(@"Started Building Hotel DB In Memory");
        NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"USA-HotelMotel" ofType:@"csv"] encoding:NSASCIIStringEncoding error:nil];
        NSArray *lines = [data componentsSeparatedByString:@"\n"];
        
        NSInteger count = lines.count - 1;
        
        TBQuadTreeNodeData *dataArray = malloc(sizeof(TBQuadTreeNodeData) * count);
        for (NSInteger i = 0; i < count; i++) {
            dataArray[i] = TBDataFromLine(lines[i]);
        }
        
        TBBoundingBox world = TBBoundingBoxMake(19, -166, 72, -53);
        TBQuadTreeNode *root = TBQuadTreeBuildWithData(dataArray, (int)count, world, 4);
        DDLogInfo(@"Finished Building Hotel DB In Memory");
        
        __block NSUInteger nodeCount = 0;
        
        [[RLMRealm defaultRealm] beginWriteTransaction];
        DDLogInfo(@"Started Building Hotel DB");
        TBQuadTreeTraverse(root, ^(TBQuadTreeNode *currentNode) {
            @autoreleasepool {
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
            }
        });
        
        [[RLMRealm defaultRealm] commitWriteTransaction];
        DDLogInfo(@"Finished Building Hotel DB");
        
        self.treeBuilt = YES;
    }
}

// INITIAL ATTEMPT TO BUILD TREE INTO REALM DIRECTLY--> MEMORY CRASH

- (void)buildTreeDirectlyInRealm
{
    if ([self checkOnTree]) {
        [self createTreeDirectlyInRealm];
    }
}

- (void)createTreeDirectlyInRealm
{
    [self createRootNode];
    DDLogInfo(@"Created Root Node");
    
    NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"USA-HotelMotel" ofType:@"csv"] encoding:NSASCIIStringEncoding error:nil];
    NSArray *lines = [data componentsSeparatedByString:@"\n"];
    NSInteger count = lines.count - 1;
    
    // Get the root node from Realm
    RLMResults *rootNode = [QuadTreeNode objectsWhere:@"isRoot == YES"];
    
    if (rootNode.count == 1) {
        QuadTreeNode *root = [rootNode firstObject];
        
        // Break up the writing blocks into smaller portions
        // by starting a new transaction
        NSInteger batchSize = 500;
        NSInteger totalBatches = count % batchSize ? count/batchSize + 1 : count/batchSize;
        
        DDLogInfo(@"Started Building Hotel DB");
        DDLogInfo(@"Total Batches:%li", (long)totalBatches);
        DDLogInfo(@"Batch Size:%li", (long)batchSize);
        
        for (NSInteger idx1 = 0; idx1 < totalBatches; idx1++) {
            NSUInteger startPoint = idx1 * batchSize;
            
            NSUInteger length = batchSize < count - idx1 * batchSize ? batchSize : count - idx1 * batchSize;
            
            NSArray *subArray = [lines subarrayWithRange:NSMakeRange(startPoint,length)];
            
            DDLogInfo(@"Processing Batch:%li", (long)idx1);
            
            [[RLMRealm defaultRealm] beginWriteTransaction];
            
            for (NSString *line in subArray) {
                @autoreleasepool {
                    QuadTreeNodeData *data = [self dataFromLine:line];
                    [self quadTreeNode:root insertData:data];
                }
            }
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
        }
        DDLogInfo(@"Finished Building Hotel DB");
    }
    
    self.treeBuilt = YES;
}

- (void)quadTreeBuildWithData:(NSArray *)data
{
    
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

- (QuadTreeNodeData *)dataFromLine:(NSString *)line
{
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

- (BOOL)checkOnTree
{
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

- (void)createRootNode
{
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

#pragma mark - Bounding Box Methods

- (BOOL)boundingBox:(BoundingBox *)box containsData:(QuadTreeNodeData *)data
{
    
    BOOL containsX = box.x <= data.latitude && data.latitude <= box.width;
    BOOL containsY = box.y <= data.longitude && data.longitude <= box.height;
    
    return containsX && containsY;
}

- (BOOL)boundingBox:(BoundingBox *)b1 intersectsBoundingBox:(BoundingBox *)b2
{
    
    return (b1.x <= b2.width && b1.width >= b2.x && b1.y <= b2.height && b1.height >= b2.y);
}

- (MKMapRect)mapRectForBoundingBox:(BoundingBox *)boundingBox
{
    MKMapRect mapRect = MKMapRectMake(boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height);
    
    return mapRect;
}

- (RLMResults *)boundingBoxesForCoordinate:(CLLocationCoordinate2D)coordinate
{
    // Before query on Realm (Chain queries for faster results)
    
    // First Find If Latitude Matches X boundaries
    RLMResults *latGreaterThanX = [BoundingBox objectsWhere:@"x <= %f", coordinate.latitude];
    RLMResults *latLessThanWidth = [latGreaterThanX objectsWhere:@"width >= %f", coordinate.latitude];
    
    // Now Find If Longitude Matches Y Boundaries
    RLMResults *lonGreaterThanY = [latLessThanWidth objectsWhere:@"y <= %f", coordinate.longitude];
    RLMResults *lonLessThanHeight = [lonGreaterThanY objectsWhere:@"height >= %f", coordinate.longitude];
    
    if (lonLessThanHeight.count > 0) {
        return lonLessThanHeight;
    }
    else {
        return nil;
    }
}

#pragma mark - QuadTreeNode Methods

- (QuadTreeNode *)nodeForBoundingBox:(BoundingBox *)box
{
    QuadTreeNode *node = [QuadTreeNode objectForPrimaryKey:box.key];
    
    return node;
}

- (QuadTreeNode *)nodeForCoordinate:(CLLocationCoordinate2D)coordinate
{
    RLMResults *boxes = [self boundingBoxesForCoordinate:coordinate];
    
    if (boxes) {
        for (BoundingBox *box in boxes) {
            QuadTreeNode *node = [self nodeForBoundingBox:box];
            
            // Get the leaf
            if (!node.northWest) {
                return node;
            }
        }
    }
    
    return nil;
}

#pragma mark - Circular Region Methods

- (BOOL)circle:(MKCircle *)circle containsData:(QuadTreeNodeData *)data
{
    
    CLLocation *dataLocation = [[CLLocation alloc] initWithLatitude:data.latitude
                                                                longitude:data.longitude];
                                      
    CLLocation *circleCenterLocation = [[CLLocation alloc] initWithLatitude:circle.coordinate.latitude
                                                                  longitude:circle.coordinate.longitude];
    
    double distanceMeters = [dataLocation distanceFromLocation:circleCenterLocation];
    
    if (distanceMeters > circle.radius) {
        return NO;
    }
    else {
        return YES;
    }
}

- (BOOL)circle:(MKCircle *)circle intersectsBoundingBox:(BoundingBox *)box
{
    MKMapRect mapRect = [self mapRectForBoundingBox:box];
    BOOL intersects = [circle intersectsMapRect:mapRect];
    
    return intersects;
}

#pragma mark - Quad Tree Methods

- (void)quadTreeNodeSubdivide:(QuadTreeNode *)node
{
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
}

- (BOOL)quadTreeNode:(QuadTreeNode *)node insertData:(QuadTreeNodeData *)data
{
    
    // Bail if our coordinate is not in the boundingBox
    if (![self boundingBox:node.boundingBox containsData:data]) {
        return NO;
    }
    
    // Add the coordinate to the points array
    if (node.points.count < node.bucketCapacity) {

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
           completionBlock:(DataReturnBlock)block
{
    
    if (![self boundingBox:node.boundingBox intersectsBoundingBox:range]) {
        return;
    }
    
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

- (void)quadTreeGatherData:(QuadTreeNode *)node
                    circle:(MKCircle *)circle
           completionBlock:(DataReturnBlock)block
{
    
    if (![self circle:circle intersectsBoundingBox:node.boundingBox]) {
        return;
    }
    
    for (QuadTreeNodeData *data in node.points) {
        if ([self circle:circle containsData:data]) {
            block(data);
        }
    }
    
    if (!node.northWest) {
        return;
    }
    
    [self quadTreeGatherData:node.northWest
                       circle:circle
             completionBlock:block];
    
    [self quadTreeGatherData:node.northEast
                       circle:circle
             completionBlock:block];
    
    [self quadTreeGatherData:node.southWest
                       circle:circle
             completionBlock:block];
    
    [self quadTreeGatherData:node.southEast
                       circle:circle
             completionBlock:block];
}

- (NSArray *)sortedNodeDataFromCoordinate:(CLLocationCoordinate2D)coordinate
                               maxResults:(NSUInteger)max
{
    // Get the leaf node that contains the coordinate
    QuadTreeNode *node = [self nodeForCoordinate:coordinate];
    
    // Get the root node from Realm
    RLMResults *rootNode = [QuadTreeNode objectsWhere:@"isRoot == YES"];
    
    __block NSMutableArray *gatheredData = @[].mutableCopy;
    
    if (rootNode.count == 1) {
        QuadTreeNode *root = [rootNode firstObject];
        
        BoundingBox *boundingBox = node.boundingBox;
        
        __block CLLocationDegrees maxDelta = [self maxDeltaForBoundingBox:boundingBox];
    
        while (gatheredData.count < max) {
            CLLocationDegrees currentDelta = maxDelta;
            
            [self quadTreeGatherData:root range:boundingBox completionBlock:^(QuadTreeNodeData *data) {
                // Add the node to the array
                if (![gatheredData containsObject:data]) {
                    [gatheredData addObject:data];
                }
                
                // Recalculate the farthest distance for the new coordinate
                CLLocationDegrees newDelta = [self farthestDeltaFromCentralCoordinate:coordinate
                            toSideOfBoundingBoxContainingCoordinate:data.coordindate];
                
                if (newDelta > maxDelta) {
                    maxDelta = newDelta;
                }
            }];
            
            if (maxDelta <= currentDelta) {
                maxDelta = currentDelta * 1.2;
            }
            
            MKCoordinateSpan span = MKCoordinateSpanMake(maxDelta, maxDelta);
            MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
            MKMapRect rect = [self MKMapRectForCoordinateRegion:region];
            
            boundingBox = [self boundingBoxForMapRect:rect];
        }
        
        NSArray *sortedData = [self sortNodeData:gatheredData fromCoordinate:coordinate];
        
        if (sortedData.count > max) {
            NSArray *subArray = [sortedData subarrayWithRange:NSMakeRange(0, 10)];
            
            return subArray;
        }
        else {
            return sortedData;
        }
    }
    
#ifdef DEBUG
    // Incorrect object class for toolbarItem
    NSAssert(rootNode.count == 1, @"QuadTreeNode doesn't have a parent node");
#else
    DDLogInfo(@"QuadTreeNode doesn't have a parent node");
#endif
    
    return nil;
}

// Used in nearest neighbors algorithm to calculate a new range to gather results in
- (CLLocationDegrees)farthestDeltaFromCentralCoordinate:(CLLocationCoordinate2D)centralCoordinate
                toSideOfBoundingBoxContainingCoordinate:(CLLocationCoordinate2D)coordinate
{
    QuadTreeNode *node = [self nodeForCoordinate:coordinate];
    
    BoundingBox *boundingBox = node.boundingBox;
    
    CLLocationDegrees leftDelta = ABS(boundingBox.x) - ABS(centralCoordinate.latitude);
    CLLocationDegrees topDelta = ABS(boundingBox.y) - ABS(centralCoordinate.longitude);
    CLLocationDegrees rightDelta = ABS(boundingBox.width) - ABS(centralCoordinate.latitude);
    CLLocationDegrees bottomDelta = ABS(boundingBox.height) - ABS(centralCoordinate.longitude);
    
    CLLocationDegrees maxLong = MAX(topDelta, bottomDelta);
    CLLocationDegrees maxLat = MAX(leftDelta, rightDelta);
    
    CLLocationDegrees max = MAX(maxLat, maxLong);
    
    // Remember to double this since we are comparing to centroid of square
    max *= 2;
    
    return max;
}

- (CLLocationDegrees)maxDeltaForBoundingBox:(BoundingBox *)boundingBox {
    CLLocationDegrees latDelta = ABS(boundingBox.width) - ABS(boundingBox.x);
    CLLocationDegrees lonDelta = ABS(boundingBox.height) - ABS(boundingBox.y);
    
    CLLocationDegrees max = MAX(latDelta, lonDelta);
    
    return max;
}

- (NSArray *)cornerLocationsOfBoundingBox:(BoundingBox *)boundingBox {
    CLLocation *topLeft = [[CLLocation alloc] initWithLatitude:boundingBox.x longitude:boundingBox.y];
    CLLocation *topRight = [[CLLocation alloc] initWithLatitude:boundingBox.width longitude:boundingBox.y];
    CLLocation *bottomLeft = [[CLLocation alloc] initWithLatitude:boundingBox.x longitude:boundingBox.height];
    CLLocation *bottomRight = [[CLLocation alloc] initWithLatitude:boundingBox.width longitude:boundingBox.height];
    
    return @[topLeft,
             topRight,
             bottomLeft,
             bottomRight];
}

- (NSArray *)sortedPoints:(RLMArray<QuadTreeNodeData>*)points
              fromCoordinate:(CLLocationCoordinate2D)coordinate {
    
    CLLocation *locationForCoordinate = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                                   longitude:coordinate.longitude];
    
    NSMutableArray *gatheredData = @[].mutableCopy;
    
    for (QuadTreeNodeData *data in points) {
        CLLocation *locationForData = [[CLLocation alloc] initWithLatitude:data.latitude
                                                                 longitude:data.longitude];
        
        CLLocationDistance distance = [locationForData distanceFromLocation:locationForCoordinate];
        
        data.currentDistance = distance;
        
        [gatheredData addObject:data];
    }
    
    [gatheredData sortUsingComparator:^NSComparisonResult(id a, id b) {
        QuadTreeNodeData *aData = (QuadTreeNodeData *)a;
        QuadTreeNodeData *bData = (QuadTreeNodeData *)b;
         
        NSNumber *first = @(aData.currentDistance);
        NSNumber *second = @(bData.currentDistance);
         
        return [first compare:second];
    }];
    
    return gatheredData.copy;
}

- (NSArray *)sortNodeData:(NSArray *)array
           fromCoordinate:(CLLocationCoordinate2D)coordinate {
    
    CLLocation *locationForCoordinate = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                                   longitude:coordinate.longitude];
    for (QuadTreeNodeData *data in array) {
        CLLocation *locationForData = [[CLLocation alloc] initWithLatitude:data.latitude
                                                                 longitude:data.longitude];
        
        CLLocationDistance distance = [locationForData distanceFromLocation:locationForCoordinate];
        
        [[RLMRealm defaultRealm] beginWriteTransaction];
        data.currentDistance = distance;
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }
    
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        
        QuadTreeNodeData *aData = (QuadTreeNodeData *)a;
        QuadTreeNodeData *bData = (QuadTreeNodeData *)b;
        
        NSNumber *first = @(aData.currentDistance);
        NSNumber *second = @(bData.currentDistance);
        
        return [first compare:second];
    }];
    
    return sortedArray;
}

- (void)quadTreeTraverse:(QuadTreeNode *)node completionBlock:(QuadTreeTraverseBlock)block
{
    if (!node) {
        return;
    }
    
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

// Return NO in the block to stop
- (void)quadTreeReverseTraverse:(QuadTreeNode *)node completionBlock:(QuadTreeReverseTraverseBlock)block
{
    if (!node) {
        return;
    }
    
    if (!block(node)) {
        return;
    }
    
    QuadTreeNode *parentNode = [self parentNodeForNode:node];
    
    if (!parentNode) {
        return;
    }
    
    [self quadTreeReverseTraverse:parentNode.northWest
                  completionBlock:block];
    
    [self quadTreeReverseTraverse:parentNode.northEast
                  completionBlock:block];
    
    [self quadTreeReverseTraverse:parentNode.southWest
                  completionBlock:block];
    
    [self quadTreeReverseTraverse:parentNode.southEast
                  completionBlock:block];
}

- (QuadTreeNode *)parentNodeForNodeData:(QuadTreeNodeData *)data
{
    
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

- (QuadTreeNode *)parentNodeForNode:(QuadTreeNode *)node
{
    NSArray *owners = [node linkingObjectsOfClass:@"QuadTreeNode" forProperty:@"northWest"];
    
#ifdef DEBUG
    // Incorrect object class for toolbarItem
    NSAssert(owners.count <= 1, @"QuadTreeNode should only have 1 parentNode");
#endif
    
    if (owners.count == 1) {
        return (QuadTreeNode *)[owners firstObject];
    }
    
    return  nil;
}

- (BoundingBox *)boundingBoxForMapRect:(MKMapRect)mapRect {
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    return [BoundingBox createBoundingBoxWithX:minLat y:minLon width:maxLat height:maxLon];
}

- (MKMapRect)MKMapRectForCoordinateRegion:(MKCoordinateRegion)region
{
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

#pragma mark - Functions

MKMapRect MKMapRectForOrigin(CLLocationCoordinate2D origin, CLLocationDistance distance) {
    CLLocationCoordinate2D topLeft = MKCoordinateOffsetFromCoordinate(origin, distance, distance);
    CLLocationCoordinate2D bottomRight = MKCoordinateOffsetFromCoordinate(origin, -distance, -distance);
    
    MKMapRect rect = MKMapRectMake(topLeft.latitude, topLeft.longitude, bottomRight.latitude, bottomRight.longitude);
    
    return rect;
}

CLLocationCoordinate2D MKCoordinateOffsetFromCoordinate(CLLocationCoordinate2D coordinate, CLLocationDistance offsetLatMeters, CLLocationDistance offsetLongMeters) {
    MKMapPoint offsetPoint = MKMapPointForCoordinate(coordinate);
    
    CLLocationDistance metersPerPoint = MKMetersPerMapPointAtLatitude(coordinate.latitude);
    double latPoints = offsetLatMeters / metersPerPoint;
    offsetPoint.y += latPoints;
    double longPoints = offsetLongMeters / metersPerPoint;
    offsetPoint.x += longPoints;
    
    CLLocationCoordinate2D offsetCoordinate = MKCoordinateForMapPoint(offsetPoint);
    return offsetCoordinate;
}

@end
