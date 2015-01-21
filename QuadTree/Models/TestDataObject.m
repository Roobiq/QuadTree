//
//  TestDataObject.m
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "TestDataObject.h"
#import "GeoHash.h"

@implementation TestDataObject

+ (instancetype)createTestDataObjectWithName:(NSString *)name
                                    latitude:(double)latitude
                                   longitude:(double)longitude
{
    TestDataObject *object = [[TestDataObject alloc] init];
    object.name = name;
    object.latitude = latitude;
    object.longitude = longitude;
    object.key = [GeoHash hashForLatitude:latitude
                                longitude:longitude
                                   length:12];
    
    return object;
}

+ (NSString *)primaryKey
{
    return @"key";
}

@end
