//
//  GGSDKExceptionHandler.m
//  BringgTracking
//
//  Created by Matan on 08/06/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import "GGSDKExceptionHandler.h"
#import "NSString+Extensions.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const kUncaughtExceptionHandlerSignalExceptionName = @"kUncaughtExceptionHandlerSignalExceptionName";
NSString * const kUncaughtExceptionHandlerSignalKey = @"kUncaughtExceptionHandlerSignalKey";

NSString * const kUncaughtExceptionHandlerAddressesKey = @"kUncaughtExceptionHandlerAddressesKey";
NSString * const kUncaughtExceptionHandlerStorageKey = @"kUncaughtExceptionHandlerStorageKey";


volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;


@interface GGSDKExceptionHandler()

@property (nonatomic, strong, readwrite) NSMutableArray<NSString *> *loggedExceptions;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation GGSDKExceptionHandler


+ (instancetype)sharedInstance {
    static GGSDKExceptionHandler *sharedObject = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // init the client
        sharedObject = [[self alloc] init];;
    });
    
    return sharedObject;
    
}

- (id)init{
    if (self = [super init]) {
        //
        self.userDefaults       = [NSUserDefaults standardUserDefaults];
        self.loggedExceptions   = [self loadArrayWithKey:kUncaughtExceptionHandlerStorageKey fromDefaults:self.userDefaults];
        
    }
    
    return self;
}

- (NSArray *)cachedExceptions{
    return [self loggedExceptions];
}


//MARK: - Helpers

-(NSMutableArray *)loadArrayWithKey:(NSString *)key fromDefaults:(NSUserDefaults *)defaults{
    
    NSMutableArray *retVal;
    
    // get pending location history from local storage
    id  defaultsObject = [defaults objectForKey:key];
    
    
    if (defaultsObject && [defaultsObject isKindOfClass:[NSArray class]]) {
        //backcompatibility support
        retVal = [NSMutableArray arrayWithArray:defaultsObject];
        
    } else if (defaultsObject && [defaultsObject isKindOfClass:[NSData class]]) {
        NSArray *defaultsObjectFormData = [NSKeyedUnarchiver unarchiveObjectWithData:defaultsObject];
        retVal = [NSMutableArray arrayWithArray:defaultsObjectFormData];
        
    } else {
        retVal = [NSMutableArray array];
        
    }
    
    return retVal;
}

- (NSData *)archivedDataFromArray:(NSArray *)array{
    ;
    if (!array) {
        return nil;
    }
    __block NSData *retVal;
    
    @synchronized (array) {
        retVal = [NSKeyedArchiver archivedDataWithRootObject:array];
    }
    
    return  retVal;
}

- (NSString *)execptionStringFromException:(NSException *)exception{
    
    NSArray *trace = [[exception userInfo] objectForKey:kUncaughtExceptionHandlerAddressesKey];
    
    __block NSMutableString *retVal = [NSMutableString stringWithFormat:@"%@\n%@", exception.name, exception.reason];
    
    [trace enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *line = (NSString *)obj;
            [retVal appendFormat:@"\n%@", line];
        }
    }];
    
    return retVal;
    
}

//MARK: - Actions
- (void)handleFrameworkException:(NSException *)exception{
 
    
    NSString *data = [self execptionStringFromException:exception];
    
    // save execption data
    [self saveCriticalApplicationDataForException:data];
    
    // rethrow exceptions so the app consuming the sdk can handle it
    [exception raise];
}

- (void)removeExceptionByData:(NSString *)exeptionData{
    
    if ([NSString isStringEmpty:exeptionData]) {
        return;
    }
    
    @synchronized (self.loggedExceptions) {
        [self.loggedExceptions removeObject:exeptionData];
        NSData *data = [self archivedDataFromArray:self.loggedExceptions];
        if (data != nil) {
            [self.userDefaults setObject:data forKey:kUncaughtExceptionHandlerStorageKey];
            [self.userDefaults synchronize];
        }
    }

}

- (void)saveCriticalApplicationDataForException:(NSString *)exeptionData
{
    @synchronized (self.loggedExceptions) {
         [self.loggedExceptions addObject:exeptionData];
        NSData *data = [self archivedDataFromArray:self.loggedExceptions];
        if (data != nil) {
            [self.userDefaults setObject:data forKey:kUncaughtExceptionHandlerStorageKey];
            [self.userDefaults synchronize];
        }
    }
   
}


// MARK - static methods
+ (NSArray *)backtrace{
    
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    
    for ( i = UncaughtExceptionHandlerSkipAddressCount; i < UncaughtExceptionHandlerSkipAddressCount + UncaughtExceptionHandlerReportAddressCount; i++){
        
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    
    free(strs);
    
    return backtrace;
}

//MARK: -- C methods

static void BringgSignalHandler(int signal)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:kUncaughtExceptionHandlerSignalKey];
    
    NSArray *callStack = [GGSDKExceptionHandler backtrace];
    
    [userInfo setObject:callStack forKey:kUncaughtExceptionHandlerAddressesKey];
    
    // since this is a C method we need to create an object c handler to continue process of exception
    // create a handler object to handle the exception
    [[[GGSDKExceptionHandler alloc] init]  performSelectorOnMainThread:@selector(handleFrameworkException:)  withObject:[NSException exceptionWithName:kUncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:NSLocalizedString(@"Signal %d was raised.", nil), signal] userInfo: userInfo] waitUntilDone:YES];
}

static void BringgHandleException(NSException *exception){
    
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)  {
        return;
    }
    
    NSArray *callStack = [GGSDKExceptionHandler backtrace];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:kUncaughtExceptionHandlerAddressesKey];
    
    // since this is a C method we need to create an object c handler to continue process of exception
    // create a handler object to handle the exception
    [[[GGSDKExceptionHandler alloc] init]  performSelectorOnMainThread:@selector(handleFrameworkException:)  withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo]  waitUntilDone:YES];
}


void SetupUncaughtExceptionHandler(){
    NSSetUncaughtExceptionHandler(&BringgHandleException);
    signal(SIGABRT, BringgSignalHandler);
    signal(SIGILL, BringgSignalHandler);
    signal(SIGSEGV, BringgSignalHandler);
    signal(SIGFPE, BringgSignalHandler);
    signal(SIGBUS, BringgSignalHandler);
    signal(SIGPIPE, BringgSignalHandler);
}

@end
