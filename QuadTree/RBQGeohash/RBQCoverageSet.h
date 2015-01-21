//
//  RBQCoverageSet.h
//  QuadTree
//
//  Created by Adam Fish on 1/20/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RBQCoverageSet : NSObject

@property (nonatomic, readonly) NSSet *hashes;

@property (nonatomic, readonly) double ratio;

+ (instancetype)coverageSetWithHashes:(NSSet *)hashes
                                ratio:(double)ratio;

- (void)addHash:(NSString *)hash;

@end
