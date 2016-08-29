//
//  GGRealTimeInternals.h
//  BringgTracking
//
//  Created by Matan on 29/06/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#ifndef GGRealTimeInternals_h
#define GGRealTimeInternals_h

@class SocketIOClient;

@protocol SocketIOClientDelegate <NSObject>

- (void) socketIODidConnect:(nonnull SocketIOClient *)socketIO;

- (void) socketIODidDisconnect:(nonnull SocketIOClient *)socketIO disconnectedWithError:(nullable NSError *)error;

- (void) socketIO:(nonnull SocketIOClient *)socketIO didReceiveEvent:(nonnull NSString *)eventName withData:(nullable NSArray *)eventDataItems;

- (void) socketIO:(nonnull SocketIOClient *)socketIO onError:(nonnull NSError *)error;

@end


#endif /* GGRealTimeInternals_h */
