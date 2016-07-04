//
//  GGRealTimeAdapter.h
//  BringgTracking
//
//  Created by Matan on 29/06/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"
#import "GGRealTimeInternals.h"
#import <SocketIOClientSwift/SocketIOClientSwift-Swift.h>


@interface GGRealTimeAdapter : NSObject


+ (void)addConnectionHandlerToClient:(nonnull SocketIOClient *)socketIO andDelegate:(nullable id<SocketIOClientDelegate>)delegate;


+ (void)addDisconnectionHandlerToClient:(nonnull SocketIOClient *)socketIO andDelegate:(nullable id<SocketIOClientDelegate>)delegate;


+ (void)addEventHandlerToClient:(nonnull SocketIOClient *)socketIO andDelegate:(nullable id<SocketIOClientDelegate>)delegate;

+ (void)addErrorHandlerToClient:(nonnull SocketIOClient *)socketIO andDelegate:(nullable id<SocketIOClientDelegate>)delegate;

+ (void)sendEventWithClient:(nonnull SocketIOClient *)socketIO eventName:(nonnull NSString *)eventName params:(nullable NSDictionary *)params completionHandler:(nullable SocketResponseBlock)completionHandler;

@end
