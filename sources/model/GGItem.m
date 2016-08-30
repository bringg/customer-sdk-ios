//
//  GGItem.m
//  BringgTracking
//
//  Created by Matan on 07/12/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import "GGItem.h"
#import "GGBringgUtils.h"
#import "BringgGlobals.h"

@implementation GGItem

@synthesize image,itemid,merchantid,name,pending,price,quantity,taskid,wpid;

-(nonnull instancetype)initItemWithData:(NSDictionary*__nullable)data{
    
    if (self = [super init]) {
        
        if (!data) {
            return self;
        }

        self.itemid = [GGBringgUtils numberFromJSON:data[PARAM_ITEM_INVENTORY_ID] defaultTo:@-1];
        self.taskid = [GGBringgUtils numberFromJSON:data[PARAM_ORDER_ID] defaultTo:@-1];
        self.merchantid = [GGBringgUtils numberFromJSON:data[PARAM_MERCHANT_ID] defaultTo:@-1];
        self.wpid = [GGBringgUtils numberFromJSON:data[PARAM_WAY_POINT_ID] defaultTo:nil];
        
        self.image = [GGBringgUtils stringFromJSON:data[PARAM_IMAGE] defaultTo:nil];
        self.name = [GGBringgUtils stringFromJSON:data[PARAM_NAME] defaultTo:nil];
        
        self.pending = [GGBringgUtils boolFromJSON:data[PARAM_ITEM_PENDING] defaultTo:NO];
        self.price = [GGBringgUtils doubleFromJSON:data[PARAM_ITEM_PENDING] defaultTo:0];
        self.quantity = [GGBringgUtils integerFromJSON:data[PARAM_ITEM_QUANTITY] defaultTo:0];
        
        
    }
    
    return self;
}


//MARk: NSCoding
- (id) initWithCoder:(NSCoder *)aDecoder{
    
    if (self = [super init]){
        
        self.quantity = [aDecoder decodeIntegerForKey:GGItemStoreKeyQuantity];
        
        self.pending = [aDecoder decodeBoolForKey:GGItemStoreKeyPending];
        
        self.price = [aDecoder decodeDoubleForKey:GGItemStoreKeyPrice];
        
        
        self.image = [aDecoder decodeObjectForKey:GGItemStoreKeyImage];
        self.name = [aDecoder decodeObjectForKey:GGItemStoreKeyName];
        
        self.itemid = [aDecoder decodeObjectForKey:GGItemStoreKeyInventoryID];
        self.merchantid = [aDecoder decodeObjectForKey:GGItemStoreKeyMerchantID];
        self.taskid = [aDecoder decodeObjectForKey:GGItemStoreKeyTaskID];
        self.wpid = [aDecoder decodeObjectForKey:GGItemStoreKeyWaypointID];
    }
    
    
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeInteger:quantity forKey:GGItemStoreKeyQuantity];
    
    [aCoder encodeBool:pending forKey:GGItemStoreKeyPending];
    
    [aCoder encodeDouble:price forKey:GGItemStoreKeyPrice];
    
    
    [aCoder encodeObject:image forKey:GGItemStoreKeyImage];
    [aCoder encodeObject:name forKey:GGItemStoreKeyName];
    
    [aCoder encodeObject:itemid forKey:GGItemStoreKeyInventoryID];
    [aCoder encodeObject:merchantid forKey:GGItemStoreKeyMerchantID];
    [aCoder encodeObject:taskid forKey:GGItemStoreKeyTaskID];
    [aCoder encodeObject:wpid forKey:GGItemStoreKeyWaypointID];
    
}

//MARK: how items compare to another
- (NSComparisonResult)compare:(GGItem *)object {
    if (self.itemid.integerValue < object.itemid.integerValue) {
        return NSOrderedAscending;
    }else if (self.itemid.integerValue < object.itemid.integerValue) {
        return NSOrderedDescending;
    }else{
        return NSOrderedSame;
    }
}


@end
