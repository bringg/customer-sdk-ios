//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGCustomer.h"
#import "GGBringgUtils.h"
#import "BringgGlobals.h"

@implementation GGCustomer

@synthesize customerToken,merchantId,phone, name, email,address, imageURL,facebookId, lat,lng,customerId;




-(nonnull instancetype)initWithData:(NSDictionary * _Nullable)data {
    
    if (self = [super init]) {
        
        if (data) {
            customerToken = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_ACCESS_TOKEN] defaultTo:nil];
           
            phone = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_PHONE] defaultTo:nil];
            name = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_NAME] defaultTo:nil];
            email = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_EMAIL] defaultTo:nil];
            address = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_ADDRESS] defaultTo:nil];
            imageURL = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_IMAGE] defaultTo:nil];
            facebookId = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_FACEBOOK_ID] defaultTo:nil];
            merchantId = [GGBringgUtils numberFromJSON:[data objectForKey:PARAM_MERCHANT_ID]defaultTo:nil];
            
            customerId = [GGBringgUtils integerFromJSON:[data objectForKey:PARAM_ID] defaultTo:0];
            
            lat = [GGBringgUtils doubleFromJSON:[data objectForKey:PARAM_LAT] defaultTo:0];
            lng = [GGBringgUtils doubleFromJSON:[data objectForKey:PARAM_LNG] defaultTo:0];
        }
        
        

    }

    return self;
    
}

//MARK: NSCoding
-(nullable instancetype)initWithCoder:(NSCoder * _Nonnull)aDecoder{
    if (self = [self init]) {
        
        self.customerToken = [aDecoder decodeObjectForKey:GGCustomerStoreKeyToken];
        self.phone = [aDecoder decodeObjectForKey:GGCustomerStoreKeyPhone];
        self.name = [aDecoder decodeObjectForKey:GGCustomerStoreKeyName];
        self.email = [aDecoder decodeObjectForKey:GGCustomerStoreKeyEmail];
        self.address = [aDecoder decodeObjectForKey:GGCustomerStoreKeyAddress];
        self.imageURL = [aDecoder decodeObjectForKey:GGCustomerStoreKeyImageURL];
        self.facebookId = [aDecoder decodeObjectForKey:GGCustomerStoreKeyFBID];
        self.merchantId = [aDecoder decodeObjectForKey:GGCustomerStoreKeyMerchantID];
        
        self.customerId = [aDecoder decodeIntegerForKey:GGCustomerStoreKeyID];
        self.lat = [aDecoder decodeDoubleForKey:GGCustomerStoreKeyLAT];
        self.lng = [aDecoder decodeDoubleForKey:GGCustomerStoreKeyLNG];
        
    }
    
    return self;
    
}

-(void)encodeWithCoder:(NSCoder * _Nonnull)aCoder{
    
    [aCoder encodeObject:self.customerToken forKey:GGCustomerStoreKeyToken];
    [aCoder encodeObject:self.phone forKey:GGCustomerStoreKeyPhone];
    [aCoder encodeObject:self.name forKey:GGCustomerStoreKeyName];
    [aCoder encodeObject:self.email forKey:GGCustomerStoreKeyEmail];
    [aCoder encodeObject:self.address forKey:GGCustomerStoreKeyAddress];
    [aCoder encodeObject:self.imageURL forKey:GGCustomerStoreKeyImageURL];
    [aCoder encodeObject:self.facebookId forKey:GGCustomerStoreKeyFBID];
    [aCoder encodeObject:self.merchantId forKey:GGCustomerStoreKeyMerchantID];
    
    [aCoder encodeInteger:self.customerId forKey:GGCustomerStoreKeyID];
    
    [aCoder encodeDouble:self.lat forKey:GGCustomerStoreKeyLAT];
    
    [aCoder encodeDouble:self.lng forKey:GGCustomerStoreKeyLNG];
    
}

- (nullable NSString *)getAuthIdentifier{
    if (phone && phone.length>0) {
        return phone;
    }
    
    if (email && email.length>0) {
        return email;
    }
    
    return nil;
}


@end
