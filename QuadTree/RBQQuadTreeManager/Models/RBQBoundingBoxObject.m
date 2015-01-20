//
//  RBQBoundingBoxObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/19/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQBoundingBoxObject.h"

#pragma mark - Functions

BOOL boundingBoxContainsData(RBQBoundingBoxObject *box, RBQQuadTreeDataObject *data)
{
    
    BOOL containsX = box.x <= data.latitude && data.latitude <= box.width;
    BOOL containsY = box.y <= data.longitude && data.longitude <= box.height;
    
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
    box->_height = height;
    box->_width = width;
    box->_x = x;
    box->_y = y;
    box->_key = [NSString stringWithFormat:@"%f%f%f%f",x,y,width,height];
    
    return box;
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
    return [self isEqualToObject:object];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    RBQBoundingBoxObject *box = [[RBQBoundingBoxObject allocWithZone:zone] init];
    box->_height = self.height;
    box->_width = self.width;
    box->_x = self.x;
    box->_y = self.y;
    box->_key = self.key;
    
    return box;
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self->_key = [decoder decodeObjectForKey:@"key"];
        self->_x = [decoder decodeDoubleForKey:@"x"];
        self->_y = [decoder decodeDoubleForKey:@"y"];
        self->_width = [decoder decodeDoubleForKey:@"width"];
        self->_height = [decoder decodeDoubleForKey:@"height"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.key forKey:@"key"];
    [encoder encodeDouble:self.x forKey:@"x"];
    [encoder encodeDouble:self.y forKey:@"y"];
    [encoder encodeDouble:self.width forKey:@"width"];
    [encoder encodeDouble:self.height forKey:@"height"];
}

@end
