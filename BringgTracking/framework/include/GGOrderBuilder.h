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
 
 @return the update order as a dictionary
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
 
 */
- (GGOrderBuilder *)addInventoryItem:(NSUInteger)itemId
                          quantity:(NSUInteger)count;

- (GGOrderBuilder *)setASAP:(BOOL)asap;
- (GGOrderBuilder *)setTitle:(NSString *)title;
- (GGOrderBuilder *)setTeamId:(NSUInteger)teamId;
- (GGOrderBuilder *)setTotalPrice:(double)totalPrice;




- (void)resetOrder;

@end
