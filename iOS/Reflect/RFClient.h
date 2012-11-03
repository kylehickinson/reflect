//
//  RFClient.h
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-14.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    PRServiceListUpdateTypeAdd = 0,
    PRServiceListUpdateTypeDelete
} PRServiceListUpdateType;

@class RFClient;

@protocol RFClientDelegate<NSObject>
@required

/** @name Receiving Data */

- (void)client:(RFClient *)client willReceiveDataWithLength:(uint64_t)length;
- (void)client:(RFClient *)client didRecieveData:(NSData *)data;

/** @name Browsing */

- (void)client:(RFClient *)client didFindServices:(NSArray *)services;
- (void)client:(RFClient *)client didUpdateServicesList:(NSArray *)services;

/** @name Connection */

- (void)client:(RFClient *)client didConnectToService:(NSNetService *)service;
- (void)clientDidDisconnectFromService:(RFClient *)client;

/** @name Passcode */

- (void)serverRequiresPasscodeForClient:(RFClient *)client;
- (void)client:(RFClient *)client passcodeWasInvalid:(NSString *)passcode;


@optional

- (void)clientDidBeginBrowsing:(RFClient *)client;

@end

@interface RFClient : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, NSStreamDelegate> {
    struct {
        unsigned respondsToDidBeginBrowsing:1;
    } _flags;
}

@property (nonatomic, strong) NSString *type;

@property (nonatomic, weak) id<RFClientDelegate> delegate;

@property (nonatomic, copy) NSString *passcode;

@property (nonatomic, assign, getter=isBrowsing) BOOL browsing;

- (id)initWithDelegate:(id<RFClientDelegate>)delegate;

- (void)searchForServices;

- (void)stopBrowsing;

- (void)stopStreaming;

- (void)stop;

@end
