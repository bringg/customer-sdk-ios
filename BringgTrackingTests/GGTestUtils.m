//
//  GGTestUtils.m
//  BringgTracking
//
//  Created by Matan on 05/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import "GGTestUtils.h"
#import "BringgGlobals.h"

#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"

@implementation GGTestUtils

+ (nullable NSDictionary *)parseJsonFile:(NSString *_Nonnull)fileName{
    
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    // Parse the string into JSON
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    
    if (json) {
        return json;
    }else{
        return nil;
    }

}


+(void)parseUpdateData:(NSDictionary * _Nonnull)eventData intoOrder:(GGOrder *_Nonnull *_Nonnull)order andDriver:(GGDriver *_Nonnull  *_Nonnull)driver{
    
    
    NSString *orderUUID = [eventData objectForKey:PARAM_UUID];
    NSNumber *orderStatus = [eventData objectForKey:PARAM_STATUS];
    
     *order = [[GGOrder alloc] initOrderWithData:eventData];
     *driver = [eventData objectForKey:PARAM_DRIVER] ? [[GGDriver alloc] initDriverWithData:[eventData objectForKey:PARAM_DRIVER]] : nil;
}

@end
