//
//  RFConnectedService.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-20.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The RFConnectedService class represents a service connected to the server.
 
 This would be written usually as a struct, but we can't have objects in a struct
 and I don't feel like bridging between CF and NS objects every time.
 */
@interface RFConnectedService : NSObject

/** Whether or not the service has entered a passcode—if they need too—and is ready to receive data. */
@property (nonatomic, assign) BOOL enteredPasscode;

/** The file descriptor for the socket that is opened. */
@property (nonatomic, assign) CGFloat socketDescriptor;

/** The input stream for this service. */
@property (nonatomic, strong) NSInputStream *inputStream;

/** The output stream for this service. */
@property (nonatomic, strong) NSOutputStream *outputStream;

/**
 Disconnect this client by closing its streams and closing the socket.
 */
- (void)disconnect;

@end
