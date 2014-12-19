//
//  BoundingBox.h
//  YoForce
//
//  Created by Adam Fish on 12/16/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>

@interface BoundingBox : RLMObject

@property NSString *key;
@property double x;
@property double y;
@property double height;
@property double width;

+ (BoundingBox *)createBoundingBoxWithX:(double)x
                                      y:(double)y
                                  width:(double)width
                                 height:(double)height;


@end

// This protocol enables typed collections. i.e.:
// RLMArray<BoundingBox>
//RLM_ARRAY_TYPE(BoundingBox)
