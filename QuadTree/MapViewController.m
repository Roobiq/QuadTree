//
//  MapViewController.m
//  QuadTree
//
//  Created by Adam Fish on 12/19/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "MapViewController.h"
#import "MapAnnotation.h"

#import "RBQQuadTreeManager.h"

#import <MapKit/MapKit.h>

NSString *kRBQAnnotationViewReuseID = @"RBQAnnotationViewReuseID";

@interface MapViewController () <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (assign, nonatomic) BOOL didSetUserLocation;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.mapView.userLocation) {
        [self animateMapToUserLocation:self.mapView.userLocation
                              animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (IBAction)didClickBackButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.didSetUserLocation) {
        MapAnnotation *annotation = [[MapAnnotation alloc]initWithCoordinate:mapView.centerCoordinate];
        
        annotation.title = @"Center";
        annotation.isClosest = YES;
        
        [mapView addAnnotation:annotation];
        
        [[NSOperationQueue new] addOperationWithBlock:^{
            DDLogInfo(@"Requested Annotations");
            NSArray *annotations = [self annotationsWithinMapRect:self.mapView.visibleMapRect];
            DDLogInfo(@"Returned Annotations");
            [self updateMapViewAnnotationsWithAnnotations:annotations];
            
//            // Get the 10 closest points
//            NSArray *closestPoints = [[LocationDBManager defaultManager] sortedNodeDataFromCoordinate:mapView.centerCoordinate maxResults:10];
//            
//            NSMutableArray *closestAnnotations = @[].mutableCopy;
//            
//            for (QuadTreeNodeData *data in closestPoints) {
//                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(data.latitude, data.longitude);
//                
//                if (CLLocationCoordinate2DIsValid(coordinate)) {
//                    MapAnnotation *annotation = [[MapAnnotation alloc]initWithCoordinate:coordinate];
//                    
//                    annotation.title = data.name;
//                    annotation.Id = data.Id;
//                    
//                    [closestAnnotations addObject:annotation];
//                }
//            }
//            
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                [mapView addAnnotations:closestAnnotations];
//            }];
        }];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[MKUserLocation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kRBQAnnotationViewReuseID];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:kRBQAnnotationViewReuseID];
        }
        else {
            annotationView.annotation = annotation;
        }
        
        annotationView.pinColor = MKPinAnnotationColorRed;
        
        if ([annotation isKindOfClass:[MapAnnotation class]]) {
            MapAnnotation *mapAnnotation = (MapAnnotation *)annotation;
            
            if (mapAnnotation.isClosest) {
                annotationView.pinColor = MKPinAnnotationColorPurple;
            }
        }
        
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    [self animateMapToUserLocation:userLocation animated:YES];
}

- (void)mapView:(MKMapView *)mapView
didFailToLocateUserWithError:(NSError *)error {
    DDLogInfo(@"%@", error.localizedDescription);
}

#pragma mark - Private

- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations {
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.mapView removeAnnotations:[toRemove allObjects]];
        [self.mapView addAnnotations:[toAdd allObjects]];
    }];
}

- (NSArray *)annotationsWithinMapRect:(MKMapRect)rect {
    
    __block NSMutableArray *annotations = @[].mutableCopy;
    
    RBQIndexRequest *indexRequest = [RBQIndexRequest createIndexRequestWithEntityName:@"TestDataObject"
                                                                              inRealm:[RLMRealm defaultRealm]
                                                                      latitudeKeyPath:@"latitude"
                                                                     longitudeKeyPath:@"longitude"];
    
    RBQQuadTreeManager *manager = [RBQQuadTreeManager managerForIndexRequest:indexRequest];

    [manager retrieveDataInMapRect:rect
                   dataReturnBlock:^(RBQQuadTreeDataObject *data) {
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(data.latitude, data.longitude);
            
            if (CLLocationCoordinate2DIsValid(coordinate)) {
                MapAnnotation *annotation = [[MapAnnotation alloc]initWithCoordinate:coordinate];
                
                [annotations addObject:annotation];
            }
                   }];
    
    return [NSArray arrayWithArray:annotations];
}

- (MKCoordinateRegion)coordinateRegionForAnnotations:(NSArray *)annotations {
    MKMapRect r = MKMapRectNull;
    
    for (NSUInteger i=0; i < annotations.count; ++i) {
        MKMapPoint p = MKMapPointForCoordinate(((MKPointAnnotation *)annotations[i]).coordinate);
        r = MKMapRectUnion(r, MKMapRectMake(p.x, p.y, 0, 0));
    }
    return MKCoordinateRegionForMapRect(r);
}

- (void)animateMapToUserLocation:(MKUserLocation *)userLocation animated:(BOOL)animated {
    MKMapRect visibleMapRect = self.mapView.visibleMapRect;
    NSSet *visibleAnnotations = [self.mapView annotationsInMapRect:visibleMapRect];
    BOOL annotationIsVisible = [visibleAnnotations containsObject:userLocation];
    
    if (userLocation &&
        annotationIsVisible &&
        !self.didSetUserLocation) {
        MKCoordinateRegion region = [self coordinateRegionForAnnotations:@[userLocation]];
        
        // Add a little extra space on the sides
        region.span.latitudeDelta *= 1.3;
        region.span.longitudeDelta *= 1.3;
        
        [self.mapView setRegion:region animated:animated];
        
        self.didSetUserLocation = YES;
    }
}

- (MapAnnotation *)annotationForId:(NSString *)Id {
    for (MapAnnotation *annotation in self.mapView.annotations) {
        
        // disregard the user location annotation
        if (![annotation isKindOfClass:[MKUserLocation class]] &&
            [annotation isKindOfClass:[MapAnnotation class]]) {
            
            if ([annotation.Id isEqualToString:Id]) {
                return annotation;
            }
        }
    }
    
    return nil;
}

@end
