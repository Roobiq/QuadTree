//
//  RBQGeohashUtils.m
//  QuadTree
//
//  Created by Adam Fish on 1/20/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQGeohashUtils.h"

static int RBQHashLengthToCoverBoundingBox(RBQBoundingBox *boundingBox) {
    double topLeftLon = boundingBox.topLeft.longitude;
    double topLeftLat = boundingBox.topLeft.latitude;
    double bottomRightLon = boundingBox.bottomRight.longitude;
    double bottomRightLat = boundingBox.bottomRight.latitude;
    
    BOOL isEven = TRUE;
    double minLat = -90.0,  maxLat = 90;
    double minLon = -180.0, maxLon = 180.0;
    
    for(int bits = 0 ; bits < 12 * 5 ; bits++)
    {
        if (isEven) {
            double mid = (minLon + maxLon) / 2;
            if(topLeftLon >= mid) {
                if(bottomRightLon < mid)
                    return bits / 5;
                minLon = mid;
            } else {
                if(bottomRightLon >= mid)
                    return bits / 5;
                maxLon = mid;
            }
        } else {
            double mid = (minLat + maxLat) / 2;
            if(topLeftLat >= mid) {
                if(bottomRightLat < mid)
                    return bits / 5;
                minLat = mid;
            } else {
                if(bottomRightLat >= mid)
                    return bits / 5;
                maxLat = mid;
            }
        }
        
        isEven = !isEven;
    }
    return 12;
}

static double calculateHeightDegrees(int n) {
    double a;
    if (n % 2 == 0) {
        a = 0;
    }
    else {
        a = -0.5;
    }
    double result = 180 / pow(2, 2.5 * n + a);
    return result;
}

static double calculateWidthDegrees(int n) {
    double a;
    if (n % 2 == 0) {
        a = -1;
    }
    else {
        a = -0.5;
    }
    
    double result = 180 / pow(2, 2.5 * n + a);
    return result;
}

static double to180(double d) {
    if (d < 0) {
        return -to180(fabs(d));
    }
    else {
        if (d > 180) {
            long n = round(floor((d + 180) / 360.0));
            return d - n * 360;
        } else
            return d;
    }
}

static double longitudeDiff(double a, double b) {
    a = to180(a);
    b = to180(b);
    return fabs(to180(a-b));
}

static RBQCoverageSet* coverBoundingBox(RBQBoundingBox *boundingBox, int length)
{
    double actualWidthDegreesPerHash = calculateWidthDegrees(length);
    double actualHeightDegreesPerHash = calculateHeightDegrees(length);
    
    double topLeftLon = boundingBox.topLeft.longitude;
    double topLeftLat = boundingBox.topLeft.latitude;
    double bottomRightLon = boundingBox.bottomRight.longitude;
    double bottomRightLat = boundingBox.bottomRight.latitude;
    
    NSMutableSet *hashes = [[NSMutableSet alloc] init];
    
    double diff = longitudeDiff(bottomRightLon, topLeftLon);
    double maxLon = topLeftLon + diff;
    
    for (double lat = bottomRightLat; lat <= topLeftLat; lat += actualHeightDegreesPerHash) {
        for (double lon = topLeftLon; lon <= maxLon; lon += actualWidthDegreesPerHash) {
            [hashes addObject:[GeoHash hashForLatitude:lat longitude:lon length:length]];
        }
    }
    // ensure have the borders covered
    for (double lat = bottomRightLat; lat <= topLeftLat; lat += actualHeightDegreesPerHash) {
        [hashes addObject:[GeoHash hashForLatitude:lat longitude:maxLon length:length]];
    }
    for (double lon = topLeftLon; lon <= maxLon; lon += actualWidthDegreesPerHash) {
        [hashes addObject:[GeoHash hashForLatitude:topLeftLat longitude:lon length:length]];
    }
    // ensure that the topRight corner is covered
    [hashes addObject:[GeoHash hashForLatitude:topLeftLat longitude:maxLon length:length]];
    
    double areaDegrees = diff * (topLeftLat - bottomRightLat);
    double coverageAreaDegrees = hashes.count * calculateWidthDegrees(length) * calculateHeightDegrees(length);
    double ratio = coverageAreaDegrees / areaDegrees;
    
    RBQCoverageSet *coverageSet = [RBQCoverageSet coverageSetWithHashes:hashes ratio:ratio];
    
    return coverageSet;
}

RBQCoverageSet* RBQCoverageSetForBoundingBox(RBQBoundingBox *boundingBox)
{
    RBQCoverageSet *coverage = nil;
    
    int startLength = RBQHashLengthToCoverBoundingBox(boundingBox);
    if (startLength == 0) {
        startLength = 1;
    }
    for (int length = startLength; length <= 12; length++) {
        RBQCoverageSet *c = coverBoundingBox(boundingBox, length);
        
        if (coverage.hashes.count > 4) {
            return coverage == nil ? nil : coverage;
        }
        else {
            coverage = c;
        }

    }
    //note coverage can never be nil
    return coverage;
}

@implementation RBQGeohashUtils

@end
