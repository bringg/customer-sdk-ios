//
//  GGFindMe.m
//  BringgTracking
//
//  Created by Matan on 23/06/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import "GGFindMe.h"
#import "BringgGlobals.h"
#import "GGBringgUtils.h"

@implementation GGFindMe

@synthesize url, token, enabled;

-(nullable instancetype)initWithData:(NSDictionary * _Nullable)data{
    
    if (self = [super init]) {
        
        url = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_FIND_ME_URL] defaultTo:nil];
        
        token = [GGBringgUtils stringFromJSON:[data objectForKey:PARAM_FIND_ME_TOKEN] defaultTo:nil];
        
        enabled = [GGBringgUtils boolFromJSON:[data objectForKey:PARAM_FIND_ME_ENABLED] defaultTo:NO];
    }
    
    return self;
}

- (void)update:(GGFindMe *__nullable)newFindMe{
    
    if (newFindMe) {
        if (newFindMe.url && newFindMe.url.length > 0) {
            url = newFindMe.url;
        }
        
        if (newFindMe.token && newFindMe.token.length > 0) {
            token = newFindMe.token;
        }
        
        enabled = newFindMe.enabled;
    }
}

//MARK: NSCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [self init]) {
        
        self.url   = [aDecoder decodeObjectForKey:GGFindMeStoreKeyUrl];
        self.token      = [aDecoder decodeObjectForKey:GGFindMeStoreKeyToken];
        
        self.enabled            = [aDecoder decodeBoolForKey:GGFindMeStoreKeyEnabled];
        
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.token forKey:GGFindMeStoreKeyToken];
    
    [aCoder encodeObject:self.url forKey:GGFindMeStoreKeyUrl];
    
    [aCoder encodeBool:self.enabled forKey:GGFindMeStoreKeyEnabled];
}

@end
