//
//  MapAnnotation.m
//  YoForce
//
//  Created by Adam Fish on 12/17/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
    }
    return self;
}

- (NSUInteger)hash {
    NSString *toHash = [NSString stringWithFormat:@"%.5F%.5F", self.coordinate.latitude, self.coordinate.longitude];
    return [toHash hash];
}

- (BOOL)isEqual:(id)object {
    return [self hash] == [object hash];
}

@end
