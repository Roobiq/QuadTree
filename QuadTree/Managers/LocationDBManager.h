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

typedef void(^DataReturnBlock)(QuadTreeNodeData *data);
typedef void(^QuadTreeTraverseBlock)(QuadTreeNode* currentNode);

@interface LocationDBManager : NSObject

@property (assign, nonatomic) BOOL treeBuilt;

+ (LocationDBManager *)defaultManager;

// Methods to test the creation of quadTree
- (void)buildTreeInMemoryFirst;
- (void)buildTreeDirectlyInRealm;

// Bounding box methods
- (BOOL)boundingBox:(BoundingBox *)box containsData:(QuadTreeNodeData *)data;
- (BOOL)boundingBox:(BoundingBox *)b1 intersectsBoundingBox:(BoundingBox *)b2;

// Completion block fires at every point found
- (void)quadTreeGatherData:(QuadTreeNode *)node
                     range:(BoundingBox *)range
           completionBlock:(DataReturnBlock)block;

// For use in simply travering the entire tree
- (void)quadTreeTraverse:(QuadTreeNode *)node
         completionBlock:(QuadTreeTraverseBlock)block;

@end
