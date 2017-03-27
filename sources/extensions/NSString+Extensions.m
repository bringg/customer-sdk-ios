//
//  NSString+Extensions.m
//  BringgTracking
//
//  Created by Matan on 27/03/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

+ (BOOL)isStringEmpty:(NSString *)str{
    // empty if str is nil, no characters, or only white space/line break characters
    return str == nil || str.length == 0 || [[[str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""] isEqualToString:@""];
}

@end
