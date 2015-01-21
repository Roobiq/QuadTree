//
//  RBQBoundingBox.m
//  QuadTree
//
//  Created by Adam Fish on 1/20/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQBoundingBox.h"

@implementation RBQBoundingBox

+ (instancetype)boundingBoxForMapRect:(MKMapRect)mapRect
{
    RBQBoundingBox *box = [[RBQBoundingBox alloc] init];
    
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D bottomRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    box->_topLeft = topLeft;
    box->_bottomRight = bottomRight;
    
    return box;
}

+ (instancetype)boundingBoxWithTopLeftCoordinate:(CLLocationCoordinate2D)topLeft
                                     bottomRight:(CLLocationCoordinate2D)bottomRight
{
    RBQBoundingBox *box = [[RBQBoundingBox alloc] init];
    box->_topLeft = topLeft;
    box->_bottomRight = bottomRight;
    
    return box;
}

@end
