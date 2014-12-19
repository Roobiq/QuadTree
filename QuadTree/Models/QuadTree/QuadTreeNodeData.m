//
//  QuadTreeNodeData.m
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "QuadTreeNodeData.h"

@implementation QuadTreeNodeData

// Set the primary key
+ (NSString *)primaryKey {
    return @"Id";
}

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    return @{
             @"Id" : @"",
             @"objectType" : @"",
             @"name" : @"",
             @"latitude" : @91,
             @"longitude" : @181
             };
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (QuadTreeNodeData *)createQuadTreeNodeDataWithLatitude:(double)latitude
                                               longitude:(double)longitude
                                                      Id:(NSString *)Id
                                              objectType:(NSString *)objectType
                                                    name:(NSString *)name {
    
    QuadTreeNodeData *nodeData = [[QuadTreeNodeData alloc] init];
    nodeData.latitude = latitude;
    nodeData.longitude = longitude;
    nodeData.Id = Id;
    nodeData.objectType = objectType;
    nodeData.name = name;
    
    return nodeData;
}

@end
