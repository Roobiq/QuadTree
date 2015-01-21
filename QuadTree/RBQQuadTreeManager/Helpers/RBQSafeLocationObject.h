//
//  RBQSafeLocationObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/21/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQSafeRealmObject.h"
#import <MapKit/MapKit.h>

@interface RBQSafeLocationObject : RBQSafeRealmObject

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

+ (instancetype)safeLocationObjectWithObject:(RLMObject *)object
                                  coordinate:(CLLocationCoordinate2D)coordinate;

@end
