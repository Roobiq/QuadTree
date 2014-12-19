//
//  MapAnnotation.h
//  YoForce
//
//  Created by Adam Fish on 12/17/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapAnnotation : NSObject <MKAnnotation>

@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end
