//
//  TestDataObject.h
//  QuadTree
//
//  Created by Adam Fish on 1/14/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>

@interface TestDataObject : RLMObject

@property double latitude;

@property double longitude;

@property NSString *name;

@property NSString *key;

@property BOOL isIndexed;

+ (instancetype)createTestDataObjectWithName:(NSString *)name
                                    latitude:(double)latitude
                                   longitude:(double)longitude;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<TestDataObject>
RLM_ARRAY_TYPE(TestDataObject)
