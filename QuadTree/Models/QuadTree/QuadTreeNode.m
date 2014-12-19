//
//  QuadTreeNode.m
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "QuadTreeNode.h"

@implementation QuadTreeNode

// Set the primary key
+ (NSString *)primaryKey {
    return @"key";
}

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (QuadTreeNode *)createQuadTreeNodeWithBox:(BoundingBox *)box
                             bucketCapacity:(int)capacity {
    
    QuadTreeNode *node = [[QuadTreeNode alloc] init];
    node.boundingBox = box;
    node.bucketCapacity = capacity;
    node.key = box.key;
    
    return node;
}

@end
