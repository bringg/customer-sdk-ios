//
//  GGBringgUtils.h
//  BringgTracking
//
//  Created by Matan on 8/24/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ORDER_UUID_COMPOUND_SEPERATOR @"$$" //FIXME: update this once defined by server
#define DRIVER_COMPOUND_SEPERATOR @"|"
#define WAYPOINT_COMPOUND_SEPERATOR @"^"

@interface GGBringgUtils : NSObject

/**
 *  takes a json object and tries to parse it as 'NSInteger'. if it fails it should
 *  @usage this method is also good for parsing simple 'int' . to do that just cast the result to (int)
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(NSInteger)integerFromJSON:(nullable id)jsonObject defaultTo:(NSInteger)defaultValue;

/**
 *  takes a json object and tries to parse it as 'double'. if it fails it should
 *  return the default value set
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(double)doubleFromJSON:(nullable id)jsonObject defaultTo:(double)defaultValue;

/**
 *  takes a json object and tries to parse it as 'BOOL'. if it fails it should
 *  return the default value set
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(BOOL)boolFromJSON:(nullable id)jsonObject defaultTo:(BOOL)defaultValue;


/**
 *  takes a json object and tries to parse it as  general purpose 'NSObject'. if it fails it should
 *  return the default value set
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(NSObject *_Nullable)objectFromJSON:(nullable id)jsonObject defaultTo:(NSObject * _Nullable)defaultValue;

/**
 *  takes a json object and tries to parse it as 'NSString'. if it fails it should
 *  return the default value set
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(NSString *_Nullable)stringFromJSON:(nullable id)jsonObject defaultTo:(NSString * _Nullable)defaultValue;


/**
*  takes a json object and tries to parse it as 'NSNumber'. if it fails it should
 *  return the default value set
*  @param jsonObject   the Json object to parse
*  @param defaultValue default value to return if parsing failes
*
*  @return the final result of the parsing
*/
+(NSNumber *_Nullable)numberFromJSON:(nullable id)jsonObject defaultTo:(NSNumber *_Nullable)defaultValue;


/**
 *  takes a json object and tries to parse it as 'NSArray'. if it fails it should
 *  return the default value set
 *
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+ (NSArray *_Nullable)arrayFromJSON:(nullable id)jsonObject defaultTo:(NSArray *_Nullable)defaultValue;

/**
 *  validates lat/lng coordinates. Latitude must be max/min +90 to -90
 *  Longitude : max/min +180 to -180 . 0/0 is an invalid location on earth
 *  @param latitude  double
 *  @param longitude double
 *
 *  @return is coordinate valid
 */
+(BOOL)isValidLatitude:(double)latitude andLongitude:(double)longitude;


/**
 *  creates a version of an object where sensetive data isnt printed
 *
 *  @param data original data object
 *
 *  @return Any object
 */
+ (nullable id )userPrintSafeDataFromData:(id __nullable)data;


/**
 *  parse order special compound UUID into and order UUID & shared UUID
 *
 *  @param compoundUUID         an order compound UUID
 *  @param orderUUID            order uuid pointer
 *  @param sharedUUID           shared uuid pointer
 *  @param errorPointer         pointer to an error object incase of exception
 */
+ (void)parseOrderCompoundUUID:(NSString * _Nonnull)compoundUUID toOrderUUID:(NSString *_Nonnull*_Nonnull)orderUUID andSharedUUID:(NSString *_Nonnull*_Nonnull)sharedUUID error:(NSError * _Nullable *_Nullable)errorPointer;

/**
 *  parses driver compound key into a pointer to driver uuid and shared uuid
 *
 *  @param key        the compund key
 *  @param driverUUID  driver uuid pointer
 *  @param sharedUUID shared uuid pointer
 */
+ (void)parseDriverCompoundKey:(NSString * _Nonnull)key toDriverUUID:(NSString *_Nonnull*_Nonnull)driverUUID andSharedUUID:(NSString *_Nonnull*_Nonnull)sharedUUID;


/**
 *  parses waypoint compound key into a pointer to order uuid and waypoint id
 *
 *  @param key        the compund key
 *  @param orderUUID  order uuid pointer
 *  @param waypointId waypoint id pointer
 */
+ (void)parseWaypointCompoundKey:(NSString * _Nonnull)key toOrderUUID:(NSString *_Nonnull*_Nonnull)orderUUID andWaypointId:(NSString *_Nonnull*_Nonnull)waypointId;


/**
 *  tests if string is a valid url string
 *
 *  @param urlTest the string to test
 *  @return BOOL
 */
+ (BOOL)isValidUrlString:(nonnull NSString *)urlTest;


/**
 *  test if coordiantes are actualy valid
 *
 *  @param lat latitude
 *  @param lng longitude
 *
 *  @return BOOL
 */
+ (BOOL)isValidCoordinatesWithLat:(double)lat lng:(double)lng;




/**
 *  check if path has SSL supporting scheme (https)
 *
 *  @param path path to check
 *
 *  @return BOOL
 */
+ (BOOL)isPathSchemeSSL:(nonnull NSString *)path;


/**
 *  takes a url string, removes current scheme and adds a new scheme to it (http || https)
 *
 *  @param urlString the url string to manipulate
 *  @param useSSL    should scheme be SSL
 */
+ (void)fixURLString:(NSString *__autoreleasing _Nonnull*_Nonnull)urlString forSSL:(BOOL)useSSL;

/**
 *  takes a url string and adds a url scheme to it (http || https)
 *
 *  @param urlString  the url string to manipulate
 *  @param useSSL    should scheme be SSL
 */
+ (void)addSchemeFromURLString:(NSString *__autoreleasing _Nonnull*_Nonnull)urlString withSSL:(BOOL)useSSL;


/**
 *  takes a url string and removes the scheme from it (http || https)
 *
 *  @param urlString the url string to manipulate
 */
+ (void)removeSchemeFromURLString:(NSString *__autoreleasing _Nonnull*_Nonnull)urlString;


/**
 *  takes a date string and converts it back to a date object
 *
 *  @param string   the date string to covert
 *
 *  @return Date if valid
 */
+ (nullable NSDate *)dateFromString:(nonnull NSString *)string;

@end
