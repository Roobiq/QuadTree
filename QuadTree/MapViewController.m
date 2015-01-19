//
//  MapViewController.m
//  QuadTree
//
//  Created by Adam Fish on 12/19/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "MapViewController.h"
#import "MapAnnotation.h"
#import "RBQClusterAnnotation.h"
#import "TBClusterAnnotationView.h"

#import "RBQQuadTreeManager.h"

#import <MapKit/MapKit.h>

NSString *kRBQAnnotationViewReuseID = @"RBQAnnotationViewReuseID";

@interface MapViewController () <MKMapViewDelegate, RBQQuadTreeManagerDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (assign, nonatomic) BOOL didSetUserLocation;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) RBQIndexRequest *indexRequest;
@property (strong, nonatomic) IBOutlet UIView *notificationView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *notificationViewTopConstraint;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonTopConstraint;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.indexRequest = [RBQIndexRequest createIndexRequestWithEntityName:@"TestDataObject"
                                                                  inRealm:[RLMRealm defaultRealm]
                                                          latitudeKeyPath:@"latitude"
                                                         longitudeKeyPath:@"longitude"];
    
    RBQQuadTreeManager *manager = [RBQQuadTreeManager managerForIndexRequest:self.indexRequest];
    manager.delegate = self;
    
    if (manager.isIndexing) {
        [self animateNotificationView:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.mapView.userLocation) {
        [self animateMapToUserLocation:self.mapView.userLocation
                              animated:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (IBAction)didClickBackButton:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [[NSOperationQueue new] addOperationWithBlock:^{
        double scale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        RBQQuadTreeManager *manager = [RBQQuadTreeManager managerForIndexRequest:self.indexRequest];
        NSSet *annotations = [manager clusteredAnnotationsWithinMapRect:mapView.visibleMapRect
                                                          withZoomScale:scale
                                                           titleKeyPath:@"name"
                                                        subTitleKeyPath:nil];
        
        
        [manager displayAnnotations:annotations
                          onMapView:mapView];
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *const TBAnnotatioViewReuseID = @"TBAnnotatioViewReuseID";
    
    TBClusterAnnotationView *annotationView = (TBClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:TBAnnotatioViewReuseID];
    
    if (!annotationView) {
        annotationView = [[TBClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:TBAnnotatioViewReuseID];
    }
    
    annotationView.canShowCallout = YES;
    
    if ([annotation isKindOfClass:[RBQClusterAnnotation class]]) {
        RBQClusterAnnotation *clusterAnnotation= (RBQClusterAnnotation *)annotation;
        annotationView.count = clusterAnnotation.safeObjects.count;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (UIView *view in views) {
        [self addBounceAnnimationToView:view];
    }
}

//#pragma mark - MKMapViewDelegate
//
//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    if (self.didSetUserLocation) {
//        MapAnnotation *annotation = [[MapAnnotation alloc]initWithCoordinate:mapView.centerCoordinate];
//        
//        annotation.title = @"Center";
//        annotation.isClosest = YES;
//        
//        [mapView addAnnotation:annotation];
//        
//        [[NSOperationQueue new] addOperationWithBlock:^{
//            DDLogInfo(@"Requested Annotations");
//            NSArray *annotations = [self annotationsWithinMapRect:self.mapView.visibleMapRect];
//            DDLogInfo(@"Returned Annotations");
//            [self updateMapViewAnnotationsWithAnnotations:annotations];
//            
////            // Get the 10 closest points
////            NSArray *closestPoints = [[LocationDBManager defaultManager] sortedNodeDataFromCoordinate:mapView.centerCoordinate maxResults:10];
////            
////            NSMutableArray *closestAnnotations = @[].mutableCopy;
////            
////            for (QuadTreeNodeData *data in closestPoints) {
////                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(data.latitude, data.longitude);
////                
////                if (CLLocationCoordinate2DIsValid(coordinate)) {
////                    MapAnnotation *annotation = [[MapAnnotation alloc]initWithCoordinate:coordinate];
////                    
////                    annotation.title = data.name;
////                    annotation.Id = data.Id;
////                    
////                    [closestAnnotations addObject:annotation];
////                }
////            }
////            
////            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
////                [mapView addAnnotations:closestAnnotations];
////            }];
//        }];
//    }
//}

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
//{
//    if (![annotation isKindOfClass:[MKUserLocation class]]) {
//        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kRBQAnnotationViewReuseID];
//        if (annotationView == nil) {
//            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
//                                                             reuseIdentifier:kRBQAnnotationViewReuseID];
//        }
//        else {
//            annotationView.annotation = annotation;
//        }
//        
//        annotationView.pinColor = MKPinAnnotationColorRed;
//        
//        if ([annotation isKindOfClass:[MapAnnotation class]]) {
//            MapAnnotation *mapAnnotation = (MapAnnotation *)annotation;
//            
//            if (mapAnnotation.isClosest) {
//                annotationView.pinColor = MKPinAnnotationColorPurple;
//            }
//        }
//        
//        annotationView.canShowCallout = YES;
//        annotationView.animatesDrop = YES;
//        
//        return annotationView;
//    }
//    
//    return nil;
//}

- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:(MKUserLocation *)userLocation
{
    
    [self animateMapToUserLocation:userLocation animated:YES];
}

- (void)mapView:(MKMapView *)mapView
didFailToLocateUserWithError:(NSError *)error
{
    DDLogInfo(@"%@", error.localizedDescription);
}

#pragma mark - RBQQuadTreeManagerDelegate

- (void)managerWillBeginIndexing:(RBQQuadTreeManager *)manager currentState:(RBQQuadTreeIndexState)state
{
    self.progressView.hidden = NO;
    
    self.progressLabel.text = RBQNSStringFromQuadTreeIndexState(state);
    
    self.progressView.progress = 0.f;
    
    [self animateNotificationView:YES];
}

- (void)managerDidUpdate:(RBQQuadTreeManager *)manager currentState:(RBQQuadTreeIndexState)state percentIndexed:(CGFloat)percentIndexed
{
    self.progressView.hidden = NO;
    
    self.progressLabel.text = RBQNSStringFromQuadTreeIndexState(state);
    
    self.progressView.progress = percentIndexed;
}

- (void)managerDidEndIndexing:(RBQQuadTreeManager *)manager
                 currentState:(RBQQuadTreeIndexState)state
{
    self.progressView.hidden = YES;
    
    self.progressLabel.text = RBQNSStringFromQuadTreeIndexState(state);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self animateNotificationView:NO];
    });
}

#pragma mark - Private

- (void)animateNotificationView:(BOOL)animate
{
    /*
     Per Apple's recommendations, you should call layoutIfNeeded
     on the parent view first to ensure all display updates complete
     
     Then within the animation block you must call it again after
     updating the constraints
     */
    
    [self.notificationView layoutIfNeeded];
    [self.view layoutIfNeeded];
    
    void (^animations)() = ^{
        if (animate) {
            self.notificationViewTopConstraint.constant = -20.f;
            self.backButtonTopConstraint.constant = 64.f;
        }
        else {
            self.notificationViewTopConstraint.constant = -84.f;
            self.backButtonTopConstraint.constant = 20.f;
        }
        
        [self.notificationView layoutIfNeeded];
        [self.view layoutIfNeeded];
    };
    
    [UIView animateWithDuration:0.25f
                          delay:0
                        options:kNilOptions
                     animations:animations
                     completion:nil];
}

- (NSArray *)annotationsWithinMapRect:(MKMapRect)rect
{
    
    __block NSMutableArray *annotations = @[].mutableCopy;
    
    RBQQuadTreeManager *manager = [RBQQuadTreeManager managerForIndexRequest:self.indexRequest];

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

- (MKCoordinateRegion)coordinateRegionForAnnotations:(NSArray *)annotations
{
    MKMapRect r = MKMapRectNull;
    
    for (NSUInteger i=0; i < annotations.count; ++i) {
        MKMapPoint p = MKMapPointForCoordinate(((MKPointAnnotation *)annotations[i]).coordinate);
        r = MKMapRectUnion(r, MKMapRectMake(p.x, p.y, 0, 0));
    }
    return MKCoordinateRegionForMapRect(r);
}

- (void)animateMapToUserLocation:(MKUserLocation *)userLocation animated:(BOOL)animated
{
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

- (MapAnnotation *)annotationForId:(NSString *)Id
{
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

- (void)addBounceAnnimationToView:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    
    bounceAnimation.duration = 0.6;
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++) {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    bounceAnimation.removedOnCompletion = NO;
    
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}


@end
