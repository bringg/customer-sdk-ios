//
//  GGSharedLocation.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGDriver.h"
#import "GGRating.h"

@interface GGSharedLocation : NSObject

@property (nonatomic, strong) NSString *locationUUID;
@property (nonatomic, strong) NSString *orderUUID;
@property (nonatomic, assign) NSInteger orderID;
@property (nonatomic) NSInteger waypointID;
@property (nonatomic, strong) NSString *eta;

@property (nonatomic, strong) GGDriver *driver;
@property (nonatomic, strong) GGRating *rating;
@property (nonatomic, copy) NSString *trackingURL;


/**
 *  init a SharedLocation object using json data recieved from a server response
 *
 *  @param data a dictionary representing the json response object
 *
 *  @return a SharedLocation object
 */
-(id)initWithData:(NSDictionary *)data;


@end
