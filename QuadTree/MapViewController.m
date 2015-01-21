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
#import "TestDataObject.h"
#import "RBQSafeLocationObject.h"

#import <MapKit/MapKit.h>

NSString *kRBQAnnotationViewReuseID = @"RBQAnnotationViewReuseID";

NSInteger RBQZoomScaleToZoomLevel(MKZoomScale scale)
{
    double totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0;
    NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
    NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom + floor(log2f(scale) + 0.5));
    
    return zoomLevel;
}

float RBQCellSizeForZoomScale(MKZoomScale zoomScale)
{
    NSInteger zoomLevel = RBQZoomScaleToZoomLevel(zoomScale);
    
    switch (zoomLevel) {
        case 13:
        case 14:
        case 15:
        return 64;
        case 16:
        case 17:
        case 18:
        return 32;
        case 19:
        return 16;
        default:
        return 88;
    }
}

@interface MapViewController () <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (assign, nonatomic) BOOL didSetUserLocation;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIView *notificationView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *notificationViewTopConstraint;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonTopConstraint;

@property (strong, nonatomic) NSOperationQueue *queryQueue;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.queryQueue = [[NSOperationQueue alloc] init];
    self.queryQueue.maxConcurrentOperationCount = 1;
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
    [self.queryQueue cancelAllOperations];
    
    [self.queryQueue addOperationWithBlock:^{
        
        // First get the RLMResults for the data
        NSLog(@"Started Doing Basic Query");
        RLMResults *results = [self retrieveDataInMapRect:mapView.visibleMapRect];
        NSLog(@"Finished Doing Basic Query");
        
        double scale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        
        NSLog(@"Started Doing Clustering");
        NSSet *annotations = [self clusteredAnnotationsWithData:results
                                                  withinMapRect:mapView.visibleMapRect
                                                  withZoomScale:scale];
        NSLog(@"Finished Doing Clustering");
        
        [self displayAnnotations:annotations
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

#pragma mark - Private

- (void)displayAnnotations:(NSSet *)annotations onMapView:(MKMapView *)mapView
{
    NSMutableSet *before;
    if (mapView.annotations) {
        before = [NSMutableSet setWithArray:mapView.annotations];
    }
    
    [before removeObject:[mapView userLocation]];
    NSSet *after = [NSSet setWithSet:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [mapView addAnnotations:[toAdd allObjects]];
        [mapView removeAnnotations:[toRemove allObjects]];
    }];
}

- (RLMResults *)retrieveDataInMapRect:(MKMapRect)mapRect
{
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    NSPredicate *containsX = [NSPredicate predicateWithFormat:@"%K >= %f AND %K <= %f",
                              @"latitude",
                              minLat,
                              @"latitude",
                              maxLat];
    
    NSPredicate *containsY = [NSPredicate predicateWithFormat:@"%K >= %f AND %K <= %f",
                              @"longitude",
                              minLon,
                              @"longitude",
                              maxLon];
    
    NSCompoundPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[containsX,containsY]];
    
    RLMResults *data = [TestDataObject objectsWithPredicate:finalPredicate];
    
    return data;
}

- (RLMResults *)retrieveDataInMapRect:(MKMapRect)mapRect
                             fromData:(RLMResults *)data
{
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    NSPredicate *containsX = [NSPredicate predicateWithFormat:@"%K >= %f AND %K <= %f",
                              @"latitude",
                              minLat,
                              @"latitude",
                              maxLat];
    
    NSPredicate *containsY = [NSPredicate predicateWithFormat:@"%K >= %f AND %K <= %f",
                              @"longitude",
                              minLon,
                              @"longitude",
                              maxLon];
    
    NSCompoundPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[containsX,containsY]];
    
    RLMResults *subData = [data objectsWithPredicate:finalPredicate];
    
    return subData;
}

- (NSSet *)clusteredAnnotationsWithData:(RLMResults *)data
                          withinMapRect:(MKMapRect)rect
                          withZoomScale:(MKZoomScale)zoomScale

{
    if (data.count < 50) {
        return [self annotationsForData:data];
    }
    
    double RBQCellSize = RBQCellSizeForZoomScale(zoomScale);
    double scaleFactor = zoomScale / RBQCellSize;
    
    NSInteger minX = floor(MKMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(MKMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(MKMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(MKMapRectGetMaxY(rect) * scaleFactor);
    
    NSMutableSet *clusteredAnnotations = [[NSMutableSet alloc] init];
    
    // Create nested array with mutable sets for the clusters
    NSMutableArray *coordinateArray = @[].mutableCopy;
    for (NSInteger x = minX; x <= maxX; x++) {
        
        NSMutableArray *yArray = @[].mutableCopy;
        
        for (NSInteger y = minY; y <= maxY; y++) {
            
            NSMutableSet *cluster = [[NSMutableSet alloc] init];
            
            [yArray addObject:cluster];
            
        }
        [coordinateArray addObject:yArray];
    }
    
    for (TestDataObject *object in data) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(object.latitude, object.longitude);
        
        MKMapPoint point = MKMapPointForCoordinate(coordinate);
        
        NSInteger x = floor(point.x * scaleFactor);
        NSInteger xDiff = abs(x - minX);
        
        NSInteger y = floor(point.y * scaleFactor);
        NSInteger yDiff = abs(y - minY);
        
        NSMutableSet *cluster = coordinateArray[xDiff][yDiff];
        
        RBQSafeLocationObject *safeObject = [RBQSafeLocationObject safeLocationObjectWithObject:object
                                                                                     coordinate:coordinate];
        
        [cluster addObject:safeObject];
    }
    
    // Now create the annotations
    for (NSArray *yArray in coordinateArray) {
        for (NSSet *cluster in yArray) {
            double totalLat = 0;
            double totalLon = 0;
            int count = 0;
            
            RBQClusterAnnotation *annotation = [[RBQClusterAnnotation alloc] initWithTitleKeyPath:nil
                                                                                  subTitleKeyPath:nil];
            
            for (RBQSafeLocationObject *safeObject in cluster) {
                totalLat += safeObject.coordinate.latitude;
                totalLon += safeObject.coordinate.longitude;
                count++;
                
                [annotation addSafeObjectToCluster:safeObject];
            }
            
            if (count == 1) {
                annotation.coordinate = CLLocationCoordinate2DMake(totalLat, totalLon);
            }
            else if (count > 1) {
                annotation.coordinate = CLLocationCoordinate2DMake(totalLat / count, totalLon / count);
            }
            
            [clusteredAnnotations addObject:annotation];
        }
    }
    
    return clusteredAnnotations.copy;
}

- (NSSet *)annotationsForData:(RLMResults *)allData
{
    NSMutableSet *annotations = [[NSMutableSet alloc] init];
    
    for (TestDataObject *data in allData) {
        
        RBQClusterAnnotation *annotation = [[RBQClusterAnnotation alloc] initWithTitleKeyPath:nil
                                                                              subTitleKeyPath:nil];
        
        [annotation addSafeObjectToCluster:[RBQSafeRealmObject safeObjectFromObject:data]];
        
        annotation.coordinate = CLLocationCoordinate2DMake(data.latitude, data.longitude);
        
        [annotations addObject:annotation];
    }
    
    return annotations.copy;
}

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
