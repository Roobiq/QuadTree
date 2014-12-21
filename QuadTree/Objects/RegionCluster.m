//
//  RegionCluster.m
//  QuadTree
//
//  Created by Adam Fish on 12/20/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "RegionCluster.h"

@implementation RegionCluster
@synthesize radius = _radius;

+ (instancetype)clusterWithRadius:(CLLocationDistance)radius points:(NSArray *)points {
    RegionCluster *cluster = [[RegionCluster alloc] initWithRadius:radius];
    cluster.dataPoints = points;
    
    return cluster;
}

- (id)initWithRadius:(CLLocationDistance)radius {
    self = [super init];
    
    if (self) {
        _radius = radius;
    }
    
    return self;
}

@end
