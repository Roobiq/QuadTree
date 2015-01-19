//
//  RBQClusterAnnotation.h
//  QuadTree
//
//  Created by Adam Fish on 1/18/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Realm/Realm.h>
#import "RBQSafeRealmObject.h"

@interface RBQClusterAnnotation : NSObject <MKAnnotation>

/**
 *  Central coordinate of the cluster
 */
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/**
 *  Title of the cluster. Generated dynamically based on if the cluster is 1 or if more than 1.
 */
@property (nonatomic, readonly, copy) NSString *title;

/**
 *  Subtitle of the cluster. Generated dynamically based on if the cluster is 1 or if more than 1.
 */
@property (nonatomic, readonly, copy) NSString *subtitle;

/**
 *  Collection of RBQSafeRealmObjects within the cluster.
 */
@property (nonatomic, readonly) NSSet *safeObjects;

/**
 *  Collection of RLMObjects within the cluster. These objects are generated on-demand (not thread-safe).
 */
@property (nonatomic, readonly) NSSet *objects;

- (instancetype)initWithTitleKeyPath:(NSString *)titleKeyPath
                     subTitleKeyPath:(NSString *)subTitleKeyPath;

- (void)addObjectToCluster:(RLMObject *)object;

- (void)addSafeObjectToCluster:(RBQSafeRealmObject *)safeObject;

- (void)removeObjectFromCluster:(RLMObject *)object;

- (void)removeSafeObjectFromCluster:(RBQSafeRealmObject *)safeObject;

@end
