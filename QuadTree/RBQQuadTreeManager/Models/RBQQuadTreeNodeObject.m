//
//  RBQQuadTreeNodeObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreeNodeObject.h"

@implementation RBQQuadTreeNodeObject

#pragma mark - Class

+ (instancetype)createQuadTreeNodeWithBox:(RBQBoundingBoxObject *)box
                           bucketCapacity:(int)capacity
{
    RBQQuadTreeNodeObject *node = [[RBQQuadTreeNodeObject alloc] init];
    node.boundingBox = box;
    node.bucketCapacity = capacity;
    node.key = box.key;
    
    return node;
}

#pragma mark - RLMObject

+ (NSString *)primaryKey {
    return @"key";
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQQuadTreeNodeObject *)object
{
    if (self.key &&
        object.key) {
        
        return [self.key isEqualToString:object.key];
    }
    else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqual:(id)object
{
    NSString *className = NSStringFromClass(self.class);
    
    if ([className hasPrefix:@"RLMStandalone_"]) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
}

@end
