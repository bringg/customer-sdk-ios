//
//  GGRealTimeAdapter.m
//  BringgTracking
//
//  Created by Matan on 29/06/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import "GGRealTimeAdapter.h"

@import SocketIO;

@implementation GGRealTimeAdapter

//MARK: Helper
+ (BOOL)isSocketClientConnected:(SocketIOClient *)socketIO{
    if (!socketIO) {
        return NO;
    }
    
    return socketIO.status == SocketIOStatusConnected;
}

+ (BOOL)errorAck:(id)argsData error:(NSError **)error {
    BOOL errorResult = NO;
    NSString *message;
    if ([argsData isKindOfClass:[NSString class]]) {
        NSString *data = (NSString *)argsData;
        if ([[data lowercaseString] rangeOfString:@"error"].location != NSNotFound) {
            errorResult = YES;
            message = data;
        }
        
    } else if ([argsData isKindOfClass:[NSDictionary class]]) {
        NSNumber *success = [argsData objectForKey:@"success"];
        message = [argsData objectForKey:@"message"];
        if (![success boolValue]) {
            errorResult = YES;
            
        }
    }
    if (errorResult) {
        *error = [NSError errorWithDomain:kSDKDomainRealTime code:0
                                 userInfo:@{NSLocalizedDescriptionKey:message,
                                            NSLocalizedRecoverySuggestionErrorKey:message}];
        
    }
    return errorResult;
    
}


//MARK: - Real Time Handlers
+ (nonnull NSUUID *)addConnectionHandlerToClient:(SocketIOClient *)socketIO  andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    return [socketIO on:@"connect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        //
        NSLog(@"websocket connected %@", ack);
        
        [delegate socketIODidConnect:socketIO];
    }];
    
    
}

+ (nonnull NSUUID *)addDisconnectionHandlerToClient:(SocketIOClient *)socketIO andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    return [socketIO on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        //
        
        id reasonObj = [data firstObject] ?: nil;
        
        
        NSString *reason;
        if ([reasonObj isKindOfClass:[NSString class]]) {
            reason = reasonObj;
        }else{
            reason = [reasonObj stringValue];
        }
        
        NSError *error;
        
        if (reason) {
            error = [NSError errorWithDomain:kSDKDomainRealTime code:0 userInfo:@{NSLocalizedDescriptionKey:reason}];
        }
        
        [delegate socketIODidDisconnect:socketIO disconnectedWithError:error];
        
    }];
}


+ (nonnull NSUUID *)addErrorHandlerToClient:(SocketIOClient *)socketIO andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    return [socketIO on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        //
        
        id reasonObj = [data firstObject] ?: nil;
        
        if (!reasonObj) {
            return;
        }
        
        NSString *reason;
        if ([reasonObj isKindOfClass:[NSString class]]) {
            reason = reasonObj;
        }else{
            reason = [reasonObj stringValue];
        }
        
        NSError *error = [NSError errorWithDomain:kSDKDomainRealTime code:0 userInfo:@{NSLocalizedDescriptionKey:reason}];
        
        [delegate socketIO:socketIO onError:error];
        
    }];
}


+ (void)addEventHandlerToClient:(SocketIOClient *)socketIO andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    [socketIO onAny:^(SocketAnyEvent * _Nonnull socketEvent) {
        //
        NSString *eventName         = [socketEvent event];
        NSArray *eventDataItems    = [socketEvent items];
        
        if ([eventName isEqualToString:@"connect"] ||
            [eventName isEqualToString:@"reconnect"] ||
            [eventName isEqualToString:@"disconnect"] ||
            [eventName isEqualToString:@"error"]) {
            // do not process
        }else{
            [delegate socketIO:socketIO didReceiveEvent:eventName withData:eventDataItems];
        }
        
    }];
}


//MARK: - Real Time Action

+ (void)sendEventWithClient:(nonnull SocketIOClient *)socketIO eventName:(nonnull NSString *)eventName params:(nullable NSDictionary *)params completionHandler:(nullable SocketResponseBlock)completionHandler{
    
    
    if (![self isSocketClientConnected:socketIO]) {
        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:kSDKDomainRealTime code:0
                                             userInfo:@{NSLocalizedDescriptionKey: @"Web socket disconnected.",
                                                        NSLocalizedRecoverySuggestionErrorKey: @"Web socket disconnected."}];
            completionHandler(NO, nil, error);
            
        }
        return;
        
    }
    
    NSArray *emitItems = params ? @[params] : @[];
    
    [[socketIO emitWithAck:eventName with:emitItems] timingOutAfter:10 callback:^(NSArray* data) {
        
        // data validation
        id response = [data firstObject];
        
        
        if (!response || (![response isKindOfClass:[NSString class]] && ![response isKindOfClass:[NSDictionary class]])) {
            
            if (completionHandler) {
                
                NSError *error = [NSError errorWithDomain:kSDKDomainRealTime code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"invalid data repsonse"}];
                
                completionHandler(NO, nil, error);
            }
            
            return;
        }
        
        //
       
        BOOL isTimeoutError = [response isKindOfClass:[NSString class]] &&[response isEqualToString:@"NO ACK"];
        
        if (isTimeoutError) {
            
            if (completionHandler) {
                
                NSError *error = [NSError errorWithDomain:kSDKDomainRealTime code:0
                                                 userInfo:@{NSLocalizedDescriptionKey: @"socket took too long to respond"}];
                
                completionHandler(NO, nil, error);
            }
            
            return;
        }
        
        NSError *error;
        if (![self errorAck:response error:&error]) {
            completionHandler(YES, response, nil);
            
        } else {
            completionHandler(NO, nil, error);
        }
        
        
        
    }];

}



@end
