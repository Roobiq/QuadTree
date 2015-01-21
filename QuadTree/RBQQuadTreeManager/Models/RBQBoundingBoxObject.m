//
//  RBQBoundingBoxObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQBoundingBoxObject.h"

BOOL boundingBoxContainsData(RBQBoundingBoxObject *box, RBQQuadTreeDataObject *data)
{
    
    BOOL containsX = box.x <= data.longitude && data.longitude <= box.width;
    BOOL containsY = box.y <= data.latitude && data.latitude <= box.height;
    
    return containsX && containsY;
}

BOOL boundingBoxIntersectsBoundingBox(RBQBoundingBoxObject *b1, RBQBoundingBoxObject *b2)
{
    
    return (b1.x <= b2.width && b1.width >= b2.x && b1.y <= b2.height && b1.height >= b2.y);
}

MKMapRect mapRectForBoundingBox(RBQBoundingBoxObject *boundingBox)
{
    MKMapRect mapRect = MKMapRectMake(boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height);
    
    return mapRect;
}

RBQBoundingBoxObject* boundingBoxForMapRect(MKMapRect mapRect)
{
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    return [RBQBoundingBoxObject createBoundingBoxWithX:minLat y:minLon width:maxLat height:maxLon];
}

@implementation RBQBoundingBoxObject

#pragma mark - Public Class

+ (RBQBoundingBoxObject *)createBoundingBoxWithX:(double)x
                                      y:(double)y
                                  width:(double)width
                                 height:(double)height {
    
    RBQBoundingBoxObject *box = [[RBQBoundingBoxObject alloc] init];
    box.height = height;
    box.width = width;
    box.x = x;
    box.y = y;
    box.key = [NSString stringWithFormat:@"%f%f%f%f",x,y,width,height];
    
    return box;
}

#pragma mark - RLMObject
// Set the primary key
+ (NSString *)primaryKey {
    return @"key";
}

#pragma mark - Equality

- (BOOL)isEqualToObject:(RBQBoundingBoxObject *)object
{
    if (self.key &&
        object.key) {
        
        return [self.key isEqualToString:object.key];
    }
    else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqual:(id)object
{
    NSString *className = NSStringFromClass(self.class);
    
    if ([className hasPrefix:@"RLMStandalone_"]) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
}



@end
