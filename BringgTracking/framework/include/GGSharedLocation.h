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

@property (nonatomic, readonly) NSString *locationUUID;
@property (nonatomic, readonly) NSString *orderUUID;
@property (nonatomic) NSInteger waypointID;
@property (nonatomic, readonly) NSString *eta;

@property (nonatomic, readonly) GGDriver *driver;
@property (nonatomic, readonly) GGRating *rating;

-(id)initWithData:(NSDictionary *)data;


@end
