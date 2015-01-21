//
//  RBQCoverageSet.m
//  QuadTree
//
//  Created by Adam Fish on 1/20/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQCoverageSet.h"
#import "RBQGeohashUtils.h"

@interface RBQCoverageSet ()

@property (nonatomic, strong) NSMutableSet *internalSet;

@end

@implementation RBQCoverageSet

+ (instancetype)coverageSetWithHashes:(NSSet *)hashes
                                ratio:(double)ratio
{
    RBQCoverageSet *coverage = [[RBQCoverageSet alloc] init];
    
    coverage->_internalSet = [[NSMutableSet alloc] initWithCapacity:hashes.count];
    coverage->_ratio = ratio;
    
    for (NSString *hash in hashes) {

        @synchronized(coverage.internalSet) {
            [coverage.internalSet addObject:hash];
        }
    }
    
    return coverage;
}

- (NSSet *)hashes
{
    @synchronized(self.internalSet) {
        return self.internalSet.copy;
    }
}

- (void)addHash:(NSString *)hash
{
    @synchronized(self.internalSet) {
        [self.internalSet addObject:hash];
    }
}


@end
