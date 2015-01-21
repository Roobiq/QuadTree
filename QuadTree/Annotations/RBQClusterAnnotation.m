//
//  RBQClusterAnnotation.m
//  QuadTree
//
//  Created by Adam Fish on 1/18/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQClusterAnnotation.h"

@interface RBQClusterAnnotation ()

@property (nonatomic, strong) NSString *titleKeyPath;

@property (nonatomic, strong) NSString *subTitleKeyPath;

@property (nonatomic, strong) NSMutableSet *internalSafeObjects;

@end

@implementation RBQClusterAnnotation

- (instancetype)initWithTitleKeyPath:(NSString *)titleKeyPath
                     subTitleKeyPath:(NSString *)subTitleKeyPath
{
    self = [super init];
    if (self) {
        _titleKeyPath = titleKeyPath;
        _subTitleKeyPath = subTitleKeyPath;
        _internalSafeObjects = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - Public Instance

- (void)addObjectToCluster:(RLMObject *)object
{
    @synchronized(self.internalSafeObjects) {
        [self.internalSafeObjects addObject:[RBQSafeRealmObject safeObjectFromObject:object]];
    }
}

- (void)addSafeObjectToCluster:(RBQSafeRealmObject *)safeObject
{
    @synchronized(self.internalSafeObjects) {
        [self.internalSafeObjects addObject:safeObject];
    }
}

- (void)removeObjectFromCluster:(RLMObject *)object
{
    @synchronized(self.internalSafeObjects) {
        if ([self.internalSafeObjects containsObject:[RBQSafeRealmObject safeObjectFromObject:object]]) {
            [self.internalSafeObjects removeObject:[RBQSafeRealmObject safeObjectFromObject:object]];
        }
    }
}

- (void)removeSafeObjectFromCluster:(RBQSafeRealmObject *)safeObject
{
    @synchronized(self.internalSafeObjects) {
        if ([self.internalSafeObjects containsObject:safeObject]) {
            [self.internalSafeObjects removeObject:safeObject];
        }
    }
}

#pragma mark - Getters

- (NSString *)title
{
    if (self.safeObjects.count == 1) {
        RBQSafeRealmObject *safeObject = [self.internalSafeObjects anyObject];
        
        return @"";
    }
    else {
        return [NSString stringWithFormat:@"%lu objects in this area", (unsigned long)self.safeObjects.count];
    }
}

- (NSString *)subtitle
{
    if (self.safeObjects.count == 1) {
        RBQSafeRealmObject *safeObject = [self.internalSafeObjects anyObject];
        
        return [[safeObject RLMObject] valueForKeyPath:self.subTitleKeyPath];
    }
    else {
        return @"";
    }
}

- (NSSet *)safeObjects
{
    @synchronized(self.internalSafeObjects) {
        return self.internalSafeObjects.copy;
    }
}

- (NSSet *)objects
{
    NSSet *safeObjects = nil;
    
    @synchronized(self.internalSafeObjects) {
        safeObjects = self.internalSafeObjects.copy;
    }
    
    if (safeObjects) {
        NSMutableSet *objects = [[NSMutableSet alloc] init];
        
        for (RBQSafeRealmObject *safeObject in safeObjects) {
            [objects addObject:[safeObject RLMObject]];
        }
        
        return objects.copy;
    }
    
    return nil;
}

#pragma mark - Equality

- (NSUInteger)hash
{
    NSString *toHash = [NSString stringWithFormat:@"%.5F%.5F", self.coordinate.latitude, self.coordinate.longitude];
    return [toHash hash];
}

- (BOOL)isEqual:(id)object
{
    return [self hash] == [object hash];
}

@end
