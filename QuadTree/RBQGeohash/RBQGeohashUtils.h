//
//  RBQGeohashUtils.h
//  QuadTree
//
//  Created by Adam Fish on 1/20/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "RBQBoundingBox.h"
#import "RBQCoverageSet.h"
#import "GeoHash.h"

///**
// * Returns a geohash of length {@link GeoHash#MAX_HASH_LENGTH} (12) for the
// * given WGS84 point (latitude,longitude).
// *
// * @param latitude
// *            in decimal degrees (WGS84)
// * @param longitude
// *            in decimal degrees (WGS84)
// * @return hash at given point of default length
// */
//NSString* RBQEncodeHash(double latitude, double longitude);
//
///**
// * Returns a geohash of length {@link GeoHash#MAX_HASH_LENGTH} (12) for the
// * given WGS84 point (latitude,longitude).
// *
// * @param latitude
// *            in decimal degrees (WGS84)
// * @param longitude
// *            in decimal degrees (WGS84)
// * @return hash at given point of default length
// */
//NSString* RBQEncodeHashWithLength(double latitude, double longitude, int length);
//
///**
// * Returns a geohash of given length for the given WGS84 point.
// *
// * @param p
// *            point
// * @param length
// *            length of hash
// * @return hash at point of given length
// */
//NSString* RBQEncodeHashFromCoordinateWithLength(CLLocationCoordinate2D coordinate, int length);
//
///**
// * Returns a geohash of of length {@link GeoHash#MAX_HASH_LENGTH} (12) for
// * the given WGS84 point.
// *
// * @param p
// *            point
// * @return hash of default length
// */
//NSString* RBQEncodeHashFromCoordinate(CLLocationCoordinate2D coordinate);
//
///** Takes a hash represented as a long and returns it as a string.
// *
// * @param hash the hash, with the length encoded in the 4 least significant bits
// * @return the string encoded geohash
// */
//NSString* RBQConvertNumberHashToString(NSNumber *hash);
//
///**
// * Returns a latitude,longitude pair as the centre of the given geohash.
// * Latitude will be between -90 and 90 and longitude between -180 and 180.
// *
// * @param geohash
// * @return lat long point
// */
//// Translated to java from:
//// geohash.js
//// Geohash library for Javascript
//// (c) 2008 David Troy
//// Distributed under the MIT License
//CLLocationCoordinate2D RBQDecodeHashToCoordinate(NSString *geohash);
//
///**
// * Returns the maximum length of hash that covers the bounding box. If no
// * hash can enclose the bounding box then 0 is returned.
// *
// * @param topLeftLat
// * @param topLeftLon
// * @param bottomRightLat
// * @param bottomRightLon
// * @return
// */
//int RBQHashLengthToCoverBoundingBox(RBQBoundingBox *boundingBox);
//
///**
// * Returns true if and only if the bounding box corresponding to the hash
// * contains the given lat and long.
// *
// * @param hash
// * @param lat
// * @param lon
// * @return
// */
//BOOL RBQHashContainsCoordinate(NSString *hash, CLLocationCoordinate2D coordinate);

/**
 * Returns the result of coverBoundingBoxMaxHashes with a maxHashes value of
 * {@link GeoHash}.DEFAULT_MAX_HASHES.
 *
 * @param topLeftLat
 * @param topLeftLon
 * @param bottomRightLat
 * @param bottomRightLon
 * @return
 */
RBQCoverageSet* RBQCoverageSetForBoundingBox(RBQBoundingBox *boundingBox);

///**
// * Returns the hashes that are required to cover the given bounding box. The
// * maximum length of hash is selected that satisfies the number of hashes
// * returned is less than <code>maxHashes</code>. Returns null if hashes
// * cannot be found satisfying that condition. Maximum hash length returned
// * will be {@link GeoHash}.MAX_HASH_LENGTH.
// *
// * @param topLeftLat
// * @param topLeftLon
// * @param bottomRightLat
// * @param bottomRightLon
// * @param maxHashes
// * @return
// */
//RBQCoverageSet* RBQCoverageSetForBoundingBoxWithMax(RBQBoundingBox *boundingBox,
//                                                    int maxHashes);
//
///**
// * Returns the hashes of given length that are required to cover the given
// * bounding box.
// *
// * @param topLeftLat
// * @param topLeftLon
// * @param bottomRightLat
// * @param bottomRightLon
// * @param length
// * @return
// */
//RBQCoverageSet* RBQCoverageSetForBoundingBoxWithLength(RBQBoundingBox *boundingBox,
//                                                       int length);

@interface RBQGeohashUtils : NSObject

@end
