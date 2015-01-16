//
//  RBQIndexRequest.h
//  QuadTree
//
//  Created by Adam Fish on 1/15/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface RBQIndexRequest : NSObject

/**
 *  The RLMRealm in which the entity that will be indexed is in. 
 
    @warning *Important:* The Realm is generated on demand and must be used on the same thread it was called from.
 */
@property (nonatomic, readonly) RLMRealm *realm;

/**
 *  RLMObject class name that contains the coordinate information to index
 */
@property (nonatomic, readonly) NSString *entityName;

/**
 *  Key path to the latitude value on the RLMObject used to index
 */
@property (nonatomic, readonly) NSString *latitudeKeyPath;

/**
 *  Key path to the longitude value on the RLMObject used to index
 */
@property (nonatomic, readonly) NSString *longitudeKeyPath;

/**
 *  Constructor method for RBQIndexRequest
 *
 *  @param entityName       The entity or class name of an RLMObject to be indexed
 *  @param realm            The realm in which the entity is persisted
 *  @param latitudeKeyPath  The key path for the latitude value (double) on the RLMObject
 *  @param longitudeKeyPath The key path for the longitude value (double) on the RLMObject
 *
 *  @return An instance of RBQIndexRequest
 */
+ (instancetype)createIndexRequestWithEntityName:(NSString *)entityName
                                         inRealm:(RLMRealm *)realm
                                 latitudeKeyPath:(NSString *)latitudeKeyPath
                                longitudeKeyPath:(NSString *)longitudeKeyPath;


@end
