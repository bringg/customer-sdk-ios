//
//  GGItem.h
//  BringgTracking
//
//  Created by Matan on 07/12/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>


#define GGItemStoreKeyInventoryID @"inventory_id"
#define GGItemStoreKeyMerchantID @"merchant_id"
#define GGItemStoreKeyTaskID @"task_id"
#define GGItemStoreKeyWaypointID @"way_point_id"
#define GGItemStoreKeyImage @"image"
#define GGItemStoreKeyName @"name"
#define GGItemStoreKeyPending @"pending"
#define GGItemStoreKeyPrice @"price"
#define GGItemStoreKeyQuantity @"quantity"


@interface GGItem : NSObject<NSCoding>

@property (nullable, nonatomic, strong) NSString *image;
@property (nullable, nonatomic, strong) NSString *name;

@property (nonatomic) BOOL pending;
@property (nonatomic) double price;
@property (nonatomic) NSUInteger quantity;

@property (nonnull, nonatomic, strong) NSNumber *itemid;
@property (nonnull, nonatomic, strong) NSNumber *merchantid;
@property (nonnull, nonatomic, strong) NSNumber *taskid;
@property (nullable, nonatomic, strong) NSNumber *wpid;


-(nonnull instancetype)initItemWithData:(NSDictionary*__nullable)data;

@end

/*
 
id = 9662;
"inventory_id" = 1138;
"merchant_id" = 1;
pending = 0;
price = 200;
quantity = 2;
"scan_string" = code2;
scanned = 0;
"task_id" = 324034;
"way_point_id" = "<null>";
*/