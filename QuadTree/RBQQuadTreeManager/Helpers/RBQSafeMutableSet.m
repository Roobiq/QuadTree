//
//  RBQSafeMutableSet.m
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSafeMutableSet.h"

@interface RBQSafeMutableSet ()

@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) NSMutableSet *mutableSet;

@end

@implementation RBQSafeMutableSet

- (id)init
{
    self = [super init];
    
    if (self) {
        _concurrentQueue = dispatch_queue_create("com.Roobiq.RBQSafeMutableSet.concurrentQueue",
                                                 DISPATCH_QUEUE_CONCURRENT);
        
        _mutableSet = [[NSMutableSet alloc] init];
    }
    
    return self;
}

#pragma mark - NSSet

- (NSUInteger)count
{
    __block NSUInteger count;
    
    dispatch_sync(self.concurrentQueue, ^(){
        count = self.mutableSet.count;
    });
    
    return count;
}

- (NSArray *)allObjects
{
    __block NSArray *allObjects;
    
    dispatch_sync(self.concurrentQueue, ^(){
        allObjects = self.mutableSet.allObjects;
    });
    
    return allObjects;
}

- (id)anyObject
{
    __block id anyObject;
    
    dispatch_sync(self.concurrentQueue, ^(){
        anyObject = [self.mutableSet anyObject];
    });
    
    return anyObject;
}

- (BOOL)containsObject:(id)anObject
{
    __block BOOL containsObject;
    
    dispatch_sync(self.concurrentQueue, ^(){
        containsObject = [self.mutableSet containsObject:anObject];
    });
    
    return containsObject;
}

- (NSSet *)filteredSetUsingPredicate:(NSPredicate *)predicate
{
    __block NSSet *filteredSet;
    
    dispatch_sync(self.concurrentQueue, ^(){
        filteredSet = [self.mutableSet filteredSetUsingPredicate:predicate];
    });
    
    return filteredSet;
}

- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet makeObjectsPerformSelector:aSelector];
    });
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet makeObjectsPerformSelector:aSelector withObject:argument];
    });
}

- (id)member:(id)object
{
    __block id member;
    
    dispatch_sync(self.concurrentQueue, ^(){
        member = [self.mutableSet member:object];
    });
    
    return member;
}

- (void)enumerateObjectsUsingBlock:(void (^)(id, BOOL *))block
{
    dispatch_async(self.concurrentQueue, ^(){
        [self.mutableSet enumerateObjectsUsingBlock:block];
    });
}

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id, BOOL *))block
{
    dispatch_async(self.concurrentQueue, ^(){
        [self.mutableSet enumerateObjectsWithOptions:opts usingBlock:block];
    });
}

- (NSSet *)objectsPassingTest:(BOOL (^)(id, BOOL *))predicate
{
    __block NSSet *objects;
    
    dispatch_sync(self.concurrentQueue, ^(){
        objects = [self.mutableSet objectsPassingTest:predicate];
    });
    
    return objects;
}

- (NSSet *)objectsWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, BOOL *))predicate
{
    __block NSSet *objects;
    
    dispatch_sync(self.concurrentQueue, ^(){
        objects = [self.mutableSet objectsWithOptions:opts passingTest:predicate];
    });
    
    return objects;
}

- (BOOL)isSubsetOfSet:(NSSet *)otherSet
{
    __block BOOL isSubsetOfSet;
    
    dispatch_sync(self.concurrentQueue, ^(){
        isSubsetOfSet = [self.mutableSet isSubsetOfSet:otherSet];
    });
    
    return isSubsetOfSet;
}

- (BOOL)intersectsSet:(NSSet *)otherSet
{
    __block BOOL intersectsSet;
    
    dispatch_sync(self.concurrentQueue, ^(){
        intersectsSet = [self.mutableSet intersectsSet:otherSet];
    });
    
    return intersectsSet;
}

- (BOOL)isEqualToSet:(NSSet *)otherSet
{
    __block BOOL isEqualToSet;
    
    dispatch_sync(self.concurrentQueue, ^(){
        isEqualToSet = [self.mutableSet isEqualToSet:otherSet];
    });
    
    return isEqualToSet;
}

- (id)valueForKey:(NSString *)key
{
    __block id value;
    
    dispatch_sync(self.concurrentQueue, ^(){
        value = [self.mutableSet valueForKey:key];
    });
    
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet setValue:value forKey:key];
    });
}

- (NSArray *)sortedArrayUsingDescriptors:(NSArray *)sortDescriptors
{
    __block id sortedArray;
    
    dispatch_sync(self.concurrentQueue, ^(){
        sortedArray = [self.mutableSet sortedArrayUsingDescriptors:sortDescriptors];
    });
    
    return sortedArray;
}

#pragma mark - NSMutableSet

- (void)addObject:(id)object
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet addObject:object];
    });
}

- (void)filterUsingPredicate:(NSPredicate *)predicate
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet filterUsingPredicate:predicate];
    });
}

- (void)removeObject:(id)object
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet removeObject:object];
    });
}

- (void)removeAllObjects
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet removeAllObjects];
    });
}

- (void)addObjectsFromArray:(NSArray *)array
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet addObjectsFromArray:array];
    });
}

- (void)unionSet:(NSSet *)otherSet
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet unionSet:otherSet];
    });
}

- (void)minusSet:(NSSet *)otherSet
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet minusSet:otherSet];
    });
}

- (void)intersectSet:(NSSet *)otherSet
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet intersectSet:otherSet];
    });
}

- (void)setSet:(NSSet *)otherSet
{
    dispatch_barrier_async(self.concurrentQueue, ^(){
        [self.mutableSet setSet:otherSet];
    });
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    __block id copy;
    
    dispatch_sync(self.concurrentQueue, ^(){
        copy = [self.mutableSet copyWithZone:zone];
    });
    
    return copy;
}

#pragma mark - <NSMutableCopying>

- (id)mutableCopyWithZone:(NSZone *)zone
{
    __block id copy;
    
    dispatch_sync(self.concurrentQueue, ^(){
        copy = [self.mutableSet mutableCopyWithZone:zone];
    });
    
    return copy;
}

#pragma mark - <NSFastEnumeration>

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len
{
    return [self.mutableSet countByEnumeratingWithState:state
                                                objects:buffer
                                                  count:len];
}

@end
