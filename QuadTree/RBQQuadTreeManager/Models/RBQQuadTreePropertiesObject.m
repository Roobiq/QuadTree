//
//  RBQQuadTreePropertiesObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/16/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQQuadTreePropertiesObject.h"
#import "RBQQuadTreeDataObject.h"

double kRBQPercentChangeUntilReindex = 0.2;

@implementation RBQQuadTreePropertiesObject

#pragma mark - Public Class

+ (instancetype)createQuadTreePropertiesWithIndexRequest:(RBQIndexRequest *)indexRequest
{
    RBQQuadTreePropertiesObject *properties = [[RBQQuadTreePropertiesObject alloc] init];
    properties.key = (NSInteger)indexRequest.hash;
    
    return properties;
}

#pragma mark - RLMObject

+ (NSString *)primaryKey
{
    return @"key";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"totalInitialPoints" : @0,
             @"quadTreeIndexState" : @0
             };
}

#pragma mark - Getters

- (NSInteger)totalPoints
{
    return [RBQQuadTreeDataObject allObjectsInRealm:self.realm].count;
}

- (BOOL)needsIndexing
{
    return self.totalPoints < (self.totalInitialPoints * (1 - kRBQPercentChangeUntilReindex));
}

@end
