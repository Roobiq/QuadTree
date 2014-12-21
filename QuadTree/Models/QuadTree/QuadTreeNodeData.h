//
//  QuadTreeNodeData.h
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
#import "QuadTreeNode.h"

#import <MapKit/MapKit.h>

@interface QuadTreeNodeData : RLMObject

// Related Object Info
@property NSString *Id;
@property NSString *objectType;
@property NSString *name;

// Default values create an invalid coordinate
// CLLocationCoordinate2DIsValid(CLLocationCoordinate2D) if necessary
@property double latitude;
@property double longitude;
@property (readonly) CLLocationCoordinate2D coordindate;

// Ignored Properties
@property double currentDistance;

// Convenience Method
+ (QuadTreeNodeData *)createQuadTreeNodeDataWithLatitude:(double)latitude
                                               longitude:(double)longitude
                                                      Id:(NSString *)Id
                                              objectType:(NSString *)objectType
                                                    name:(NSString *)name;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<QuadTreeNodeData>
//RLM_ARRAY_TYPE(QuadTreeNodeData)
