//
//  RBQQuadTreeNodeObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreeNodeObject.h"

@implementation RBQQuadTreeNodeObject

#pragma mark - Public Class

+ (instancetype)createQuadTreeNodeWithBox:(RBQBoundingBoxObject *)box
                           bucketCapacity:(int)capacity
{
    RBQQuadTreeNodeObject *node = [[RBQQuadTreeNodeObject alloc] init];
    node->_points = [[RBQSafeMutableSet alloc] init];
    node->_boundingBox = box;
    node->_bucketCapacity = capacity;
    node->_key = box.key;
    
    return node;
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
    return [self isEqualToObject:object];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQQuadTreeNodeObject *node = [[RBQQuadTreeNodeObject allocWithZone:zone] init];
    
    node->_northWest = self.northWest;
    node->_northEast = self.northEast;
    node->_southWest = self.southWest;
    node->_southEast = self.southEast;
    node->_points = self.points;
    node->_boundingBox = self.boundingBox;
    node->_bucketCapacity = self.bucketCapacity;
    node->_key = self.key;
    
    return node;
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self->_northWest = [decoder decodeObjectForKey:@"northWest"];
        self->_northEast = [decoder decodeObjectForKey:@"northEast"];
        self->_southWest = [decoder decodeObjectForKey:@"southWest"];
        self->_southEast = [decoder decodeObjectForKey:@"southEast"];
        self->_points = [decoder decodeObjectForKey:@"points"];
        self->_boundingBox = [decoder decodeObjectForKey:@"boundingBox"];
        self->_bucketCapacity = [decoder decodeIntForKey:@"bucketCapacity"];
        self->_key = [decoder decodeObjectForKey:@"key"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (self.northWest) {
        [encoder encodeObject:self.northWest forKey:@"northWest"];
    }
    
    if (self.northEast) {
        [encoder encodeObject:self.northEast forKey:@"northEast"];
    }
    
    if (self.southWest) {
        [encoder encodeObject:self.southWest forKey:@"southWest"];
    }
    
    if (self.southEast) {
        [encoder encodeObject:self.southEast forKey:@"southEast"];
    }

    [encoder encodeObject:self.boundingBox forKey:@"boundingBox"];
    [encoder encodeObject:self.points forKey:@"points"];
    [encoder encodeInt:self.bucketCapacity forKey:@"bucketCapacity"];
    [encoder encodeObject:self.key forKey:@"key"];
}

@end
