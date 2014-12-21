//
//  RegionCluster.h
//  QuadTree
//
//  Created by Adam Fish on 12/20/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RegionCluster : NSObject

@property (strong, nonatomic) NSArray *dataPoints;

@property (readonly, nonatomic) CLLocationDistance radius;

+ (instancetype)clusterWithRadius:(CLLocationDistance)radius points:(NSArray *)points;

@end
