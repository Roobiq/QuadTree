//
//  RBQSafeMutableSet.h
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RBQSafeMutableSet : NSObject <NSCopying, NSMutableCopying, NSFastEnumeration>

#pragma mark - NSSet

/**
 *  The number of members in the set. (read-only)
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 *  An array containing the set’s members, or an empty array if the set has no members. (read-only)
 */
@property (nonatomic, readonly) NSArray *allObjects;

/**
 *  Returns one of the objects in the set, or nil if the set contains no objects.
 *
 *  @return One of the objects in the set, or nil if the set contains no objects. The object returned is chosen at the set’s convenience—the selection is not guaranteed to be random.
 */
- (id)anyObject;

/**
 *  Returns a Boolean value that indicates whether a given object is present in the set.
 *
 *  @param anObject The object for which to test membership of the set.
 *
 *  @return YES if anObject is present in the set, otherwise NO.
 */
- (BOOL)containsObject:(id)anObject;

/**
 *  Evaluates a given predicate against each object in the receiving set and returns a new set containing the objects for which the predicate returns true.
 *
 *  @param predicate A predicate.
 *
 *  @return A new set containing the objects in the receiving set for which predicate returns true.
 */
- (NSSet *)filteredSetUsingPredicate:(NSPredicate *)predicate;

/**
 *  Sends a message specified by a given selector to each object in the set.
 *
 *  @param aSelector A selector that specifies the message to send to the members of the set. The method must not take any arguments. It should not have the side effect of modifying the set. This value must not be NULL.
 */
- (void)makeObjectsPerformSelector:(SEL)aSelector;

/**
 *  Sends a message specified by a given selector to each object in the set.
 *
 *  @param aSelector A selector that specifies the message to send to the set's members. The method must take a single argument of type id. The method should not, as a side effect, modify the set. The value must not be NULL.
 *  @param argument  The object to pass as an argument to the method specified by aSelector.
 */
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument;

/**
 *  Determines whether the set contains an object equal to a given object, and returns that object if it is present.
 *
 *  @param object The object for which to test for membership of the set.
 *
 *  @return If the set contains an object equal to object (as determined by isEqual:) then that object (typically this will be object), otherwise nil.
 */
- (id)member:(id)object;

/**
 *  Executes a given Block using each object in the set.
 *
 *  @param block The Block to apply to elements in the set
 */
- (void)enumerateObjectsUsingBlock:(void (^)(id, BOOL *))block;

/**
 *  Executes a given Block using each object in the set, using the specified enumeration options.
 *
 *  @param opts  A bitmask that specifies the options for the enumeration.
 *  @param block The Block to apply to elements in the set.
 */
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id, BOOL *))block;

/**
 *  Returns a set of object that pass a test in a given Block.
 *
 *  @param predicate The block to apply to elements in the array.
 *
 *  @return An NSSet containing objects that pass the test.
 */
- (NSSet *)objectsPassingTest:(BOOL (^)(id, BOOL *))predicate;

/**
 *  Returns a set of object that pass a test in a given Block, using the specified enumeration options.
 *
 *  @param opts      A bitmask that specifies the options for the enumeration.
 *  @param predicate The Block to apply to elements in the set.
 *
 *  @return An NSSet containing objects that pass the test.
 */
- (NSSet *)objectsWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id, BOOL *))predicate;

/**
 *  Returns a Boolean value that indicates whether every object in the receiving set is also present in another given set.
 *
 *  @param otherSet The set with which to compare the receiving set.
 *
 *  @return YES if every object in the receiving set is also present in otherSet, otherwise NO.
 */
- (BOOL)isSubsetOfSet:(NSSet *)otherSet;

/**
 *  Returns a Boolean value that indicates whether at least one object in the receiving set is also present in another given set.
 *
 *  @param otherSet The set with which to compare the receiving set.
 *
 *  @return YES if at least one object in the receiving set is also present in otherSet, otherwise NO
 */
- (BOOL)intersectsSet:(NSSet *)otherSet;

/**
 *  Compares the receiving set to another set.
 *
 *  @param otherSet The set with which to compare the receiving set.
 *
 *  @return YES if the contents of otherSet are equal to the contents of the receiving set, otherwise NO.
 */
- (BOOL)isEqualToSet:(NSSet *)otherSet;

/**
 *  Return a set containing the results of invoking valueForKey: on each of the receiving set's members.
 *
 *  @param key The name of one of the properties of the receiving set's members.
 *
 *  @return A set containing the results of invoking valueForKey: (with the argument key) on each of the receiving set's members.
 */
- (id)valueForKey:(NSString *)key;

/**
 *  Invokes setValue:forKey: on each of the set’s members.
 *
 *  @param value The value for the property identified by key.
 *  @param key   The name of one of the properties of the set's members.
 */
- (void)setValue:(id)value forKey:(NSString *)key;

/**
 *  Returns an array of the set’s content sorted as specified by a given array of sort descriptors.
 *
 *  @param sortDescriptors An array of NSSortDescriptor objects
 *
 *  @return An NSArray containing the set’s content sorted as specified by sortDescriptors.
 */
- (NSArray *)sortedArrayUsingDescriptors:(NSArray *)sortDescriptors;

#pragma mark - NSMutableSet

/**
 *  Adds a given object to the set, if it is not already a member.
 *
 *  @param object The object to add to the set.
 */
- (void)addObject:(id)object;

/**
 *  Evaluates a given predicate against the set’s content and removes from the set those objects for which the predicate returns false.
 *
 *  @param predicate A predicate.
 */
- (void)filterUsingPredicate:(NSPredicate *)predicate;

/**
 *  Removes a given object from the set.
 *
 *  @param object The object to remove from the set.
 */
- (void)removeObject:(id)object;

/**
 *  Empties the set of all of its members.
 */
- (void)removeAllObjects;

/**
 *  Adds to the set each object contained in a given array that is not already a member.
 *
 *  @param array An array of objects to add to the set.
 */
- (void)addObjectsFromArray:(NSArray *)array;

/**
 *  Adds each object in another given set to the receiving set, if not present.
 *
 *  @param otherSet The set of objects to add to the receiving set.
 */
- (void)unionSet:(NSSet *)otherSet;

/**
 *  Removes each object in another given set from the receiving set, if present.
 *
 *  @param otherSet The set of objects to remove from the receiving set.
 */
- (void)minusSet:(NSSet *)otherSet;

/**
 *  Removes from the receiving set each object that isn’t a member of another given set.
 *
 *  @param otherSet The set with which to perform the intersection.
 */
- (void)intersectSet:(NSSet *)otherSet;

/**
 *  Empties the receiving set, then adds each object contained in another given set.
 *
 *  @param otherSet The set whose members replace the receiving set's content.
 */
- (void)setSet:(NSSet *)otherSet;

@end
