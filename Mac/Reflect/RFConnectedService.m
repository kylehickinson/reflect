//
//  RFConnectedService.m
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-20.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFConnectedService.h"

@implementation RFConnectedService

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RFConnectedService class]]) {
        return ((RFConnectedService *)object).socketDescriptor == self.socketDescriptor;
    }
    return NO;
}

- (id)init
{
    if ((self = [super init])) {
        self.enteredPasscode = NO;
        self.socketDescriptor = 0;
    }
    return self;
}

- (void)disconnect
{
    [self.inputStream close];
    [self.outputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    close(self.socketDescriptor);
}

@end
