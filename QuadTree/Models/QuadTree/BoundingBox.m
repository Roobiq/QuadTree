//
//  BoundingBox.m
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "BoundingBox.h"

@implementation BoundingBox

// Set the primary key
+ (NSString *)primaryKey {
    return @"key";
}

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (BoundingBox *)createBoundingBoxWithX:(double)x
                                      y:(double)y
                                  width:(double)width
                                 height:(double)height {
    
    BoundingBox *box = [[BoundingBox alloc] init];
    box.height = height;
    box.width = width;
    box.x = x;
    box.y = y;
    box.key = [NSString stringWithFormat:@"%f%f%f%f",x,y,width,height];
    
    return box;
}

@end
