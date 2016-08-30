//
//  GGOrderBuilder.h
//  BringgTracking
//
//  Created by Matan on 6/29/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGOrderBuilder : NSObject

@property (nonatomic, getter=orderData) NSDictionary *orderData;


/**
 adds a waypoint to the order object and the order builder reporesenting the order after the update.
 
 @param latitude waypoint latitude.
 @param longitude waypoint longitude.
 @param address waypoint address.
 @param phone waypoint phone.
 @param email waypoint email.
 @param notes array of strings representing each note
 
 @return the updated order builder object
 */
- (GGOrderBuilder *)addWaypointAtLatitude:(double)lat
                              longitude:(double)lng
                                address:(NSString *)address
                                  phone:(NSString *)phone
                                  email:(NSString *)email
                                  notes:(NSString *)notes;


/**
 adds an inventory item to the order object and returns the order builder reporesenting the order after the update.
 @param itemId the id of the inventory item
 @param quantity the items count for this inventory item
 @return the updated order builder object
 
 */
- (GGOrderBuilder *)addInventoryItem:(NSUInteger)itemId
                          quantity:(NSUInteger)count;

/**
 *  set the ASAP param of an order
 *
 *  @param asap bool stating the asap mode
 *
 *  @return the updated order builder object
 */
- (GGOrderBuilder *)setASAP:(BOOL)asap;

/**
 *  set the order title
 *
 *  @param title
 *
 *  @return the updated order builder object
 */
- (GGOrderBuilder *)setTitle:(NSString *)title;

/**
 *  set team id for order
 *
 *  @param teamId
 *
 *  @return the updated order builder object
 */
- (GGOrderBuilder *)setTeamId:(NSUInteger)teamId;

/**
 *  set the total price of the order
 *
 *  @param totalPrice double
 *
 *  @return the updated order builder object
 */
- (GGOrderBuilder *)setTotalPrice:(double)totalPrice;


/**
 *  get the number of waypoints currently in the builder data
 *
 *  @return number of waypoints
 */
- (NSUInteger)numWaypoints;

/**
 *  resets the data of the builder object
 */
- (void)resetOrder;

@end
