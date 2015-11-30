//
//  NSObject+Observer.m
//  BringgTracking
//
//  Created by Matan on 30/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import "NSObject+Observer.h"

static NSMutableSet *observedKeys;

@implementation NSObject (Observer)

+ (void)addObserver:(NSObject *)observer toObject:(NSObject *)reciever options:(NSKeyValueObservingOptions)options context:(void *)context count:(NSInteger)count, ... {
    va_list args;
    va_start(args, count);
    for( int i = 0; i < count; i++ ) {
        NSString *key;
        key = va_arg(args, NSString *);
        [NSObject addObserver:observer
                          toObject:reciever
                        forKeyPath:key
                           options:options
                           context:context];
        
    }
    
    va_end(args);
    
}

+ (void)removeObserver:(NSObject *)observer fromObject:(NSObject *)reciever count:(NSInteger)count, ... {
    va_list args;
    va_start(args, count);
    for( int i = 0; i < count; i++ ) {
        NSString *key;
        key = va_arg(args, NSString *);
        [NSObject removeObserver:observer
                           fromObject:reciever
                           forKeyPath:key];
        
    }
    
    va_end(args);
}

+ (void)addObserver:(NSObject *)observer toObject:(NSObject *)reciever forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    if (!reciever) {
        return;
        
    }
    
    if(!observedKeys) {
        observedKeys = [[NSMutableSet alloc] initWithCapacity:20];
    }
    
    // add observer only if not existing
    if (![self isObservering:observer object:reciever keyPath:keyPath]) {
        [reciever addObserver:observer forKeyPath:keyPath options:options context:context];
        
        [observedKeys addObject:[NSString stringWithFormat:@"%@%@%@", reciever.description, observer.description, keyPath]];
    }
    
    
}

+ (void)removeObserver:(NSObject *)observer fromObject:(NSObject *)reciever forKeyPath:(NSString *)keyPath {
    if(!observedKeys || !reciever) {
        return;
    }
    

    // we can only remove if we are already observing
    if ([self isObservering:observer object:reciever keyPath:keyPath]) {
        NSString *theKey = [NSString stringWithFormat:@"%@%@%@", reciever.description, observer.description, keyPath];
    
         [reciever removeObserver:observer forKeyPath:keyPath];
        [observedKeys removeObject:theKey];
    }

}

+ (BOOL)isObservering:(NSObject *)observer object:(NSObject *)reciever keyPath:(NSString *)keyPath{
    
    NSString *theKey = [NSString stringWithFormat:@"%@%@%@", reciever.description, observer.description, keyPath];
    
    __block BOOL retval = NO;
    
    [observedKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        //
        NSString *key = (NSString *)obj;
        if([key isEqualToString:theKey]) {
            
            retval = YES;
            *stop = YES;
        }
    }];
    
    
    return retval;
}

@end
