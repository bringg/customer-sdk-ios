//
//  GGRealTimeAdapter.m
//  BringgTracking
//
//  Created by Matan on 29/06/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import "GGRealTimeAdapter.h"

@implementation GGRealTimeAdapter

//MARK: Helper
+ (BOOL)isSocketClientConnected:(SocketIOClient *)socketIO{
    if (!socketIO) {
        return NO;
    }
    
    return socketIO.status == SocketIOClientStatusConnected;
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
        *error = [NSError errorWithDomain:@"BringgRealTime" code:0
                                 userInfo:@{NSLocalizedDescriptionKey:message,
                                            NSLocalizedRecoverySuggestionErrorKey:message}];
        
    }
    return errorResult;
    
}


//MARK: - Real Time Handlers
+ (void)addConnectionHandlerToClient:(SocketIOClient *)socketIO  andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    [socketIO on:@"connect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        //
        NSLog(@"websocket connected %@", ack);
        
        [delegate socketIODidConnect:socketIO];
    }];
    
    
}

+ (void)addDisconnectionHandlerToClient:(SocketIOClient *)socketIO andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    [socketIO on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        //
        
        NSString *reason = [data firstObject] ? [[data firstObject] stringValue] : nil;
        NSError *error;
        
        if (reason) {
            error = [NSError errorWithDomain:@"BringgRealTime" code:0 userInfo:@{NSLocalizedDescriptionKey:reason}];
        }
        
        [delegate socketIODidDisconnect:socketIO disconnectedWithError:error];
        
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


+ (void)addErrorHandlerToClient:(SocketIOClient *)socketIO andDelegate:(id<SocketIOClientDelegate>)delegate{
    
    [socketIO on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        //
        
        NSString *reason = [data firstObject] ? [[data firstObject] stringValue] : nil;
        
        if (!reason) {
            return;
        }

        NSError *error = [NSError errorWithDomain:@"BringgRealTime" code:0 userInfo:@{NSLocalizedDescriptionKey:reason}];
        
        [delegate socketIO:socketIO onError:error];
        
    }];
}

//MARK: - Real Time Action

+ (void)sendEventWithClient:(nonnull SocketIOClient *)socketIO eventName:(nonnull NSString *)eventName params:(nullable NSDictionary *)params completionHandler:(nullable SocketResponseBlock)completionHandler{
    
    
    if (![self isSocketClientConnected:socketIO]) {
        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:@"BringgRealTime" code:0
                                             userInfo:@{NSLocalizedDescriptionKey: @"Web socket disconnected.",
                                                        NSLocalizedRecoverySuggestionErrorKey: @"Web socket disconnected."}];
            completionHandler(NO, nil, error);
            
        }
        return;
        
    }
    
    NSTimeInterval timeoutCap = 10;
    
#if DEBUG
    timeoutCap = 60;
#endif
    
    NSArray *emitItems = params ? @[params] : @[];
    
    [socketIO emitWithAck:eventName withItems:emitItems](timeoutCap, ^(NSArray * __nullable data) {
        
        // data validation
        id response = [data firstObject];
        
        
        if (!response || ![response isKindOfClass:[NSString class]]) {
            
            if (completionHandler) {
                
                NSError *error = [NSError errorWithDomain:@"BringgRealTime" code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"invalid data repsonse"}];
                
                completionHandler(NO, nil, error);
            }
            
            return;
        }
        
        //
        NSString *responseAck = (NSString *)response;
        BOOL isTimeoutError = [responseAck isEqualToString:@"NO ACK"];
        
        if (isTimeoutError) {
            
            if (completionHandler) {
                
                NSError *error = [NSError errorWithDomain:@"BringgRealTime" code:0
                                                 userInfo:@{NSLocalizedDescriptionKey: @"socket took too long to respond"}];
                
                completionHandler(NO, nil, error);
            }
            
            return;
        }
        
        NSError *error;
        if (![self errorAck:response error:&error]) {
            completionHandler(YES, responseAck, nil);
            
        } else {
            completionHandler(NO, nil, error);
        }
        
        
        
    });

}



@end
