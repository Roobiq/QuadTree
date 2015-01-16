//
//  RBQIndexRequest.m
//  QuadTree
//
//  Created by Adam Fish on 1/15/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQIndexRequest.h"

@interface RBQIndexRequest ()

@property (strong, nonatomic) NSString *realmPath;

@end

@implementation RBQIndexRequest
@synthesize entityName = _entityName,
latitudeKeyPath = _latitudeKeyPath,
longitudeKeyPath = _longitudeKeyPath;

#pragma mark - Public Class

+ (instancetype)createIndexRequestWithEntityName:(NSString *)entityName
                                         inRealm:(RLMRealm *)realm
                                 latitudeKeyPath:(NSString *)latitudeKeyPath
                                longitudeKeyPath:(NSString *)longitudeKeyPath
{
#ifdef DEBUG
    NSAssert(realm, @"Realm must not be nil!");
    NSAssert(entityName, @"Entity name must not be nil!");
    NSAssert(latitudeKeyPath, @"Latitude key path must not be nil!");
    NSAssert(longitudeKeyPath, @"Longitude key path must not be nil!");
#endif
    
    RBQIndexRequest *indexRequest = [[RBQIndexRequest alloc] init];
    indexRequest.realmPath = realm.path;
    
    indexRequest->_entityName = entityName;
    indexRequest->_latitudeKeyPath = latitudeKeyPath;
    indexRequest->_longitudeKeyPath = longitudeKeyPath;
    
    return indexRequest;
}

#pragma mark - Getters

- (RLMRealm *)realm
{
    return [RLMRealm realmWithPath:self.realmPath];
}

#pragma mark - Hash

- (NSUInteger)hash
{
    if (self.entityName &&
        self.latitudeKeyPath &&
        self.longitudeKeyPath) {
        
        return self.entityName.hash ^ self.latitudeKeyPath.hash ^ self.longitudeKeyPath.hash;
    }
    else {
        return [super hash];
    }
}


@end
