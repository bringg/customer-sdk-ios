//
//  GGOrderBuilder.m
//  BringgTracking
//
//  Created by Matan on 6/29/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGOrderBuilder.h"
#import "BringgGlobals.h"


@interface GGOrderBuilder ()

@property (nonatomic, strong) NSMutableDictionary *orderParams;

@end

@implementation GGOrderBuilder

@synthesize orderData;

- (id)init{
    
    if (self = [super init]) {
        //
        _orderParams = [NSMutableDictionary dictionary];
        [_orderParams setObject:[NSMutableArray array] forKey:@"way_points"];
    }
    
    return self;
}

#pragma mark - Helpers

-(BOOL)validateParam:(id)param{
    
    if (!param) {
        return NO;
    }else if ([param isKindOfClass:[NSString class]]){
        return [param length] > 0;
    }else if ([param isKindOfClass:[NSArray class]]){
        return [param count] > 0;
    }
    
    return YES;
}

#pragma mark - Getters

- (NSDictionary *)orderData{
    return _orderParams;
}

#pragma mark - Actions

- (GGOrderBuilder *)addWaypointAtLatitude:(double)lat
                              longitude:(double)lng
                                address:(NSString *)address
                                  phone:(NSString *)phone
                                  email:(NSString *)email
                                  notes:(NSString *)notes{
    
    
    NSMutableDictionary *waypoint = [NSMutableDictionary dictionary];
    [waypoint setObject:@(lat) forKey:@"lat"];
    [waypoint setObject:@(lng) forKey:@"lng"];
    
    if ([self validateParam:address]) [waypoint setObject:address forKey:@"address"];
    if ([self validateParam:phone]) [waypoint setObject:phone forKey:@"phone"];
    if ([self validateParam:email]) [waypoint setObject:email forKey:@"email"];
    
    if ([self validateParam:notes]){
        [waypoint setObject:notes forKey:@"notes"];
    }
    
    [[_orderParams objectForKey:@"way_points"] addObject:waypoint];
    
    return self;
};

- (GGOrderBuilder *)addInventoryItem:(NSUInteger)itemId
                          quantity:(NSUInteger)count{
    
    // make sure there is an invetory key in the order params
    if (![_orderParams objectForKey:@"inventory"]) {
        [_orderParams setObject:[NSMutableArray array] forKey:@"inventory"];
    }
    
    // create the item object as a dict
    NSDictionary *inventoryItem = @{@"id":@(itemId), @"quantity":@(count)};
    
    // add it as mutable (just in case)
    [[_orderParams objectForKey:@"inventory"] addObject:[inventoryItem mutableCopy]];
    
    return self;
}

- (GGOrderBuilder *)setASAP:(BOOL)asap{
    [_orderParams setObject:@(asap) forKey:@"asap"];
    
    return self;
}
- (GGOrderBuilder *)setTitle:(NSString *)title{
    [_orderParams setObject:title forKey:@"title"];
    
    return self;
}
- (GGOrderBuilder *)setTeamId:(NSUInteger)teamId{
    [_orderParams setObject:@(teamId) forKey:@"team_id"];
    
    return self;
}
- (GGOrderBuilder *)setTotalPrice:(double)totalPrice{
    [_orderParams setObject:@(totalPrice) forKey:@"total_price"];
    
    return self;
}

- (void)resetOrder{
    _orderParams = [NSMutableDictionary dictionary];
    [_orderParams setObject:[NSMutableArray array] forKey:@"way_points"];
}

-(NSUInteger)numWaypoints{
    return [[_orderParams objectForKey:@"way_points"] count];
}

@end
