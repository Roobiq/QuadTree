//
//  QuadTreeNode.h
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "BoundingBox.h"

RLM_ARRAY_TYPE(QuadTreeNodeData)

@interface QuadTreeNode : RLMObject

@property NSString *key;
@property QuadTreeNode *northWest;
@property QuadTreeNode *northEast;
@property QuadTreeNode *southWest;
@property QuadTreeNode *southEast;

@property BoundingBox *boundingBox;

@property RLMArray<QuadTreeNodeData> *points;

@property int bucketCapacity;

// Set only for the root node
@property BOOL isRoot;

+ (QuadTreeNode *)createQuadTreeNodeWithBox:(BoundingBox *)box
                             bucketCapacity:(int)capacity;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<QuadTreeNode>
//RLM_ARRAY_TYPE(QuadTreeNode)
