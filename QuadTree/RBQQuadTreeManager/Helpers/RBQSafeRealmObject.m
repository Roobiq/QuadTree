//
//  RBQSafeRealmObject.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/4/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSafeRealmObject.h"
#import "RLMObject+Utilities.h"

@interface RBQSafeRealmObject ()

@property (strong, nonatomic) NSString *realmPath;

@end

@implementation RBQSafeRealmObject
@synthesize className = _className,
primaryKeyType = _primaryKeyType,
primaryKeyValue = _primaryKeyValue;

+ (instancetype)safeObjectFromObject:(RLMObject *)object
{
    if (!object) {
        return nil;
    }
    
    NSString *className = [RLMObject classNameForObject:object];
    
    id value = [RLMObject primaryKeyValueForObject:object];
    
    RLMProperty *primaryKeyProperty = object.objectSchema.primaryKeyProperty;
    
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject alloc] initWithClassName:className
                                                                   primaryKeyValue:value
                                                                    primaryKeyType:primaryKeyProperty.type
                                                                             realm:object.realm];
    
    return safeObject;
}

+ (RLMObject *)objectfromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [RBQSafeRealmObject objectInRealm:[RLMRealm defaultRealm] fromSafeObject:safeObject];
}

+ (RLMObject *)objectInRealm:(RLMRealm *)realm
              fromSafeObject:(RBQSafeRealmObject *)safeObject
{
    return [NSClassFromString(safeObject.className) objectInRealm:realm forPrimaryKey:safeObject.primaryKeyValue];
}

- (id)initWithClassName:(NSString *)className
        primaryKeyValue:(id)primaryKeyValue
         primaryKeyType:(RLMPropertyType)primaryKeyType
                  realm:(RLMRealm *)realm
{
    self = [super init];
    
    if (self) {
        _className = className;
        _primaryKeyValue = primaryKeyValue;
        _primaryKeyType = primaryKeyType;
        _realmPath = realm.path;
    }
    
    return self;
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    return [RLMRealm realmWithPath:self.realmPath];
}

- (RLMObject *)RLMObject
{
    return [RBQSafeRealmObject objectInRealm:self.realm fromSafeObject:self];
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQSafeRealmObject *)object
{
    // if identical object
    if (self == object) {
        return YES;
    }
    
    if (self.primaryKeyType == RLMPropertyTypeString) {
        return [self.primaryKeyValue isEqualToString:object.primaryKeyValue];
    }
    
    return self.primaryKeyValue == object.primaryKeyValue;
}

- (BOOL)isEqual:(id)object
{
    if (self.primaryKeyValue) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
}

- (NSUInteger)hash
{
    if (self.primaryKeyValue) {
        return [self.primaryKeyValue hash];
    }
    else {
        return [super hash];
    }
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQSafeRealmObject *safeObject = [[RBQSafeRealmObject allocWithZone:zone] init];
    safeObject->_className = _className;
    safeObject->_primaryKeyValue = _primaryKeyValue;
    safeObject->_primaryKeyType = _primaryKeyType;
    safeObject->_realmPath = _realmPath;
    
    return safeObject;
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self->_className = [decoder decodeObjectForKey:@"className"];
        self->_primaryKeyValue = [decoder decodeObjectForKey:@"primaryKeyValue"];
        self->_primaryKeyType = [decoder decodeInt32ForKey:@"primaryKeyType"];
        self->_realmPath = [decoder decodeObjectForKey:@"realmPath"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.className forKey:@"className"];
    [encoder encodeObject:self.primaryKeyValue forKey:@"primaryKeyValue"];
    [encoder encodeInt32:self.primaryKeyType forKey:@"primaryKeyType"];
    [encoder encodeObject:self.realmPath forKey:@"realmPath"];
}

@end
