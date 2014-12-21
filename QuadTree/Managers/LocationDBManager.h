//
//  LocationDBManager.h
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "QuadTreeNodeData.h"
#import "BoundingBox.h"
#import "QuadTreeNode.h"

#import <MapKit/MapKit.h>


typedef void(^DataReturnBlock)(QuadTreeNodeData *data);
typedef void(^QuadTreeTraverseBlock)(QuadTreeNode* currentNode);
typedef BOOL(^QuadTreeReverseTraverseBlock)(QuadTreeNode *currentNode);

@interface LocationDBManager : NSObject

@property (assign, nonatomic) BOOL treeBuilt;

+ (LocationDBManager *)defaultManager;

// Methods to test the creation of quadTree
- (void)buildTreeInMemoryFirst;
- (void)buildTreeDirectlyInRealm;

// Bounding box methods
- (BOOL)boundingBox:(BoundingBox *)box containsData:(QuadTreeNodeData *)data;
- (BOOL)boundingBox:(BoundingBox *)b1 intersectsBoundingBox:(BoundingBox *)b2;
- (BoundingBox *)boundingBoxForMapRect:(MKMapRect)mapRect;

// Completion block fires at every point found
- (void)quadTreeGatherData:(QuadTreeNode *)node
                     range:(BoundingBox *)range
           completionBlock:(DataReturnBlock)block;

- (void)quadTreeGatherData:(QuadTreeNode *)node
                    circle:(MKCircle *)circle
           completionBlock:(DataReturnBlock)block;

// Gather results sorted by ascending distance
- (NSArray *)sortedNodeDataFromCoordinate:(CLLocationCoordinate2D)coordinate
                               maxResults:(NSUInteger)max;

// For use in simply travering the entire tree
- (void)quadTreeTraverse:(QuadTreeNode *)node
         completionBlock:(QuadTreeTraverseBlock)block;

// For use in traversing back up the tree
// NOTE: Block returns NO to stop the traversal
- (void)quadTreeReverseTraverse:(QuadTreeNode *)node
                completionBlock:(QuadTreeReverseTraverseBlock)block;

@end
