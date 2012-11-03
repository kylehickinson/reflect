//
//  RFClient.m
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-14.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFClient.h"
#import "RFPacketHeaders.h"

@interface RFClient ()

@property (nonatomic, strong) NSNetServiceBrowser *browser;

@property (nonatomic, strong) NSNetService *connectedService;

@property (nonatomic, assign) BOOL inputReady;
@property (nonatomic, assign) BOOL outputReady;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSMutableArray *services;

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) BOOL readingData;
@property (nonatomic, assign) uint64_t targetDataSize;
@property (nonatomic, assign) uint64_t totalDataRead;

@end

@implementation RFClient

- (id)init
{
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<RFClientDelegate>)delegate
{
    if ((self = [super init])) {
        self.delegate = delegate;
        self.type = @"_reflect";
    }
    return self;
}

- (void)setDelegate:(id<RFClientDelegate>)delegate
{
    _delegate = delegate;
    memset(&_flags, 0, sizeof(_flags));
    
    if (_delegate) {
        _flags.respondsToDidBeginBrowsing = [_delegate respondsToSelector:@selector(clientDidBeginBrowsing:)];
    }
}

- (void)setPasscode:(NSString *)passcode
{
    _passcode = [passcode copy];
}

- (void)searchForServices
{
    NSString *type = [NSString stringWithFormat:@"%@._tcp.", self.type];
    self.services = [[NSMutableArray alloc] init];

    if (!self.browser) {
        self.browser = [[NSNetServiceBrowser alloc] init];
        self.browser.delegate = self;
        [self.browser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    
    [self.browser searchForServicesOfType:type inDomain:@""];
}

- (void)stopBrowsing
{
    [self.browser stop];
    [self.data setLength:0];
}

- (void)stopStreaming
{
    [self.inputStream close];
    [self.outputStream close];
    
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    self.inputReady = NO;
    self.outputReady = NO;
    
    [self.connectedService stop];
    self.connectedService = nil;
}

- (void)stop
{
    // Stop both
    [self stopBrowsing];
    [self stopStreaming];
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    self.browsing = YES;
    if (_flags.respondsToDidBeginBrowsing) {
        [self.delegate clientDidBeginBrowsing:self];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    aNetService.delegate = self;
    [self.services addObject:aNetService];
    if (!moreComing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate client:self didFindServices:self.services];
        });
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.services removeObject:aNetService];
    if (!moreComing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate client:self didUpdateServicesList:self.services];
        });
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    // Handle errors...
    NSLog(@"didn't search... %@", errorDict);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    self.browsing = NO;
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [sender stop];
    [self _setupStreamsForService:sender];
}

- (void)_setupStreamsForService:(NSNetService *)sender
{
    NSInputStream *input;
    NSOutputStream *output;
    
    self.connectedService = sender;
    if (![self.connectedService getInputStream:&input outputStream:&output]) {
        NSLog(@"Failed to get input/output stream");
        return;
    }
    
    self.inputStream = input;
    self.outputStream = output;
    
    self.inputStream.delegate = self;
    self.outputStream.delegate = self;
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.inputStream open];
    [self.outputStream open];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate client:self didConnectToService:self.connectedService];
    });
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"Failed to resolve: %@", errorDict);
}

- (NSString *)_logPacketData:(uint8_t *)data size:(uint64_t)size detailed:(BOOL)detailed
{
    if (size == 0) return nil;
    
    NSMutableString *packetString = [NSMutableString string];
    for (int i = 0, x = 0; i < size; i++) {
        [packetString appendFormat:@"%02X ", data[i]];
        
        if (!detailed && (i > 16 && x == 0)) {
            [packetString appendString:@"... "];
            i = (size-16);
            x = 1;
        }
    }
    
    NSArray *headers = @[ @"RFServerSendingDataInformation", @"RFServerSendingData", @"RFServerRequiresPasscode", @"RFServerReceivedInvalidPasscode" ];
    return [NSString stringWithFormat:@"read (%@ : %lld bytes): %@", ((data[0]-RFServerSendingDataInformation) >= [headers count] ? nil : headers[data[0]-RFServerSendingDataInformation]), size, packetString];
}

- (void)_appendBytesAndCheck:(uint8_t *)bytes length:(NSInteger)length
{
    if (length == 0) return;
    
    [self.data appendBytes:bytes length:length];
    
    self.totalDataRead += length;
    
    if (self.totalDataRead == self.targetDataSize) {
        self.readingData = NO;
        
        // Jump back to the main thread for UI updates.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate client:self didRecieveData:self.data];
        });
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    static NSMutableArray *packetLog = nil;
    
    if (self.data == nil) {
        packetLog = [[NSMutableArray alloc] init];
        self.data = [[NSMutableData alloc] init];
    }
    
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            if (aStream == self.inputStream) {
                NSInteger len = 0;
                
                while ([self.inputStream hasBytesAvailable]) {
                    uint8_t buf[1024];
                    len = [self.inputStream read:buf maxLength:1024];
                    if (len > 0) {
                        [packetLog addObject:[self _logPacketData:buf size:len detailed:NO]];
                        
                        if (self.readingData) {
                            // Anything after the target data size is sent _should_ be image data.
                            // Also gotta make sure we got our first batch of data (with the begin header...)
                            [self _appendBytesAndCheck:buf length:len];
                        } else {
                            // Check packet header.
                            switch (buf[0]) {
                                case RFServerSendingDataInformation: {
                                    // Client sending length
                                    self.targetDataSize = *(uint64_t *)&buf[1];
                                    
                                    // We could proably do something with the length here, like say check disk space?
                                    
                                    // Send the OK.
                                    uint8_t header = RFClientSendingOK;
                                    [self.outputStream write:&header maxLength:sizeof(uint8_t)];
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.delegate client:self willReceiveDataWithLength:self.targetDataSize];
                                    });
                                    
                                    break;
                                }
                                    
                                case RFServerBeginSendingData: {
                                    // Reset data
                                    [self.data setLength:0];
                                    self.totalDataRead = 0;
                                    self.readingData = YES;
                                    
                                    // Append data sent over (not including the packet header)
                                    [self _appendBytesAndCheck:&buf[1] length:(len-1)];
                                    break;
                                }
                                    
                                case RFServerRequiresPasscode: {
                                    [self.delegate serverRequiresPasscodeForClient:self];
                                    break;
                                }
                                    
                                case RFServerReceivedInvalidPasscode: {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            break;
        }
        case NSStreamEventOpenCompleted: {
            if (aStream == self.inputStream) {
                self.inputReady = YES;
            } else if (aStream == self.outputStream) {
                self.outputReady = YES;
            }
            
            if (self.inputReady && self.outputReady) {
                [self.connectedService stop];
                self.connectedService = nil;
            }
            break;
        }
        case NSStreamEventErrorOccurred: {
            NSLog(@"Error occured with error: %@", aStream.streamError);
        }
            
        case NSStreamEventEndEncountered: {
            [packetLog removeAllObjects];
            [self stopStreaming];
            [self.delegate clientDidDisconnectFromService:self];
            
        }
            
        default:
            break;
    }
}

@end
