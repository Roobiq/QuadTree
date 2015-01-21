//
//  RBQBoundingBox.h
//  QuadTree
//
//  Created by Adam Fish on 1/20/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface RBQBoundingBox : NSObject

@property (nonatomic, readonly) CLLocationCoordinate2D topLeft;

@property (nonatomic, readonly) CLLocationCoordinate2D bottomRight;

+ (instancetype)boundingBoxForMapRect:(MKMapRect)mapRect;

+ (instancetype)boundingBoxWithTopLeftCoordinate:(CLLocationCoordinate2D)topLeft
                                     bottomRight:(CLLocationCoordinate2D)bottomRight;

@end
