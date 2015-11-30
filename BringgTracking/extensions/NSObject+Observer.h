//
//  NSObject+Observer.h
//  BringgTracking
//
//  Created by Matan on 30/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Observer)


/**
 *  adds an observer to multiple key paths of an observed object
 *
 *  @param observer the observer object
 *  @param reciever the observed object
 *  @param options  observation option
 *  @param context  context
 *  @param count    amount of key paths
 *  @param arguments  the keypaths to start observing
 */
+ (void)addObserver:(NSObject *)observer toObject:(NSObject *)reciever options:(NSKeyValueObservingOptions)options context:(void *)context count:(NSInteger)count, ...;

/**
 *  remove multople key path observerations from an object
 *
 *  @param observer the observer object
 *  @param reciever the observed object
 *  @param count    the amount of keys observeed
 *  @param arguments  the keypaths to stop observing
 */
+ (void)removeObserver:(NSObject *)observer fromObject:(NSObject *)reciever count:(NSInteger)count, ...;

/**
 *  adds an observer to a recievers specific keypath
 *
 *  @param observer the observer object
 *  @param reciever the observed object
 *  @param keyPath  key path to observer
 *  @param options  observing options
 *  @param context  context
 */
+ (void)addObserver:(NSObject *)observer toObject:(NSObject *)reciever forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;

/**
 *  stop observing a key path of an observed object
 *
 *  @param observer the observer object
 *  @param reciever the oserved object
 *  @param keyPath  the key path observed
 */
+ (void)removeObserver:(NSObject *)observer fromObject:(NSObject *)reciever forKeyPath:(NSString *)keyPath;

/**
 *  checks if an object is observing a keypath of another object
 *
 *  @param observer observing object
 *  @param reciever reciever object
 *  @param keyPath  key path observed
 *
 *  @return BOOL
 */
+ (BOOL)isObservering:(NSObject *)observer object:(NSObject *)reciever keyPath:(NSString *)keyPath;

@end
