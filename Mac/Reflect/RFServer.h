//
//  RFServer.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-13.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const RFServerErrorDomain;

typedef enum {
    // The server failed to bind to the socket.
    RFServerFailedBindError = -6000L,
    
    // The server failed at getting the socket name.
    RFServerFailedGetSocketNameError = -6001L,
    
    // The server failed at starting to listen for connections.
    RFServerFailedListenError = -6002L
    
} RFServerErrorCode;

@class RFServer;

/**
 */
@protocol RFServerDelegate<NSObject>
@optional

/**
 Tell the delegate that the server failed to start the bonjour service.
 
 @param server The RFServer object that sent this.
 @param error The error that caused the failure.
 
 @note The `userInfo` property of the error paramater contains the original error dictionary 
 given by NSNetServiceDelegate
 */
- (void)server:(RFServer *)server didFailToStartBonjourWithError:(NSError *)error;

/**
 Tell the delegate that the bonjour service was succesfully registered and is to be discoverable.
 
 @param server The RFServer object that sent this.
 */
- (void)serverDidStartBonjourService:(RFServer *)server;

/**
 Tell the delegate that the server failed to start that isn't a bonjour related error.
 
 @param server The RFServer object that sent this.
 @param error The error that caused the failure.  The domain should be RFServerErrorDomain, with a given 
 code from the RFServerErrorCode enumeration.
 
 */
- (void)server:(RFServer *)server didFailToStartWithError:(NSError *)error;

@end

/**
 The RFServer class registers a bonjour service and handles all networking traffic between the clients. 
 This server can have multiple clients, and will send the image to each client upon changing the data 
 property.
 
 RFServer contains a delegate (RFServerDelegate) that is used to notify of certain actions that the 
 server takes such as when bonjour starts/fails to start.
 */
@interface RFServer : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate, NSStreamDelegate> {
    struct {
        unsigned respondsToDidFailBonjour:1;
        unsigned respondsToDidStartBonjour:1;
        unsigned respondsToDidFailStart:1;
    } _flags;
}

/** @name Bonjour Configuration */

/**
 The name that will appear when a client browses for bonjour services with this classes type.
 
 Defaults to `nil`.  If this property is nil, the name that is shown while browsing will be the name
 of the Mac.  (This name is located—and can be changed—in System Preferences.app > Sharing : Computer Name)
 
 @note This property must be changed before -start is called.
 */
@property (nonatomic, copy) NSString *name;

/**
 The type of service that you are registering for in bonjour.  Bonjour follows the format: [_type]._tcp.
 
 Defaults to **_reflect**.  If this value is changed, the client source must also be changed to browse for
 this given type or else it will fail to discover the server.
 
 @note This property must be changed before -start is called.
 */
@property (nonatomic, copy) NSString *type;

/**
 The passcode required to access the server.
 
 Defaults to `nil`, in which a passcode is not needed and will send data to any client.
 
 @note This property must be changed before -start is called.
 */
@property (nonatomic, copy) NSString *passcode;

/** @name Delegate */

/** The delegate object that receives server actions */
@property (nonatomic, weak) id<RFServerDelegate> delegate;

/** @name Starting & Stopping */

/** `YES` if the server succesfully started, bonjour registered, and is running, `NO` otherwise. */
@property (readonly, getter=isRunning) BOOL running;

/** Start the server */
- (void)start;

/** Stop the server */
- (void)stop;

/** @name Sending Data */

/**
 The data that is being transferred to a client.
 
 Setting this (to something different) will automatically update all clients with the new data.
 */
@property (nonatomic, strong) NSData *data;

@end
