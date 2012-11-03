//
//  RFServer.m
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-13.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFServer.h"
#import "RFConnectedService.h"
#import "RFPacketHeaders.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

NSString * const RFServerErrorDomain = @"RFServerErrorDomain";

@interface RFServer ()

@property (nonatomic, strong) NSNetService *bonjourNetService;
@property (nonatomic, assign) int socketDescriptor;

@property (nonatomic, strong) NSMutableArray *connectedServices;

- (void)_registerBonjourServiceWithPort:(in_port_t)port;
- (NSStream *)_setupAndOpenStream:(NSStream *)stream;
- (void)_connectSocket:(int)socket toInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;

- (void)_updateAllClientData;
- (void)_updateClientData:(RFConnectedService *)service;

@end

@implementation RFServer

static void ListeningSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

- (id)init
{
    if ((self = [super init])) {
        self.name = @"";
        self.type = @"_reflect";
        self.connectedServices = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setDelegate:(id<RFServerDelegate>)delegate
{
    _delegate = delegate;
    
    memset(&_flags, 0, sizeof(_flags));
    if (_delegate) {
        _flags.respondsToDidFailBonjour = [_delegate respondsToSelector:@selector(server:didFailToStartBonjourWithError:)];
        _flags.respondsToDidStartBonjour = [_delegate respondsToSelector:@selector(serverDidStartBonjourService:)];
        _flags.respondsToDidFailStart = [_delegate respondsToSelector:@selector(server:didFailToStartWithError:)];
    }
}

- (void)setData:(NSData *)data
{
    // Don't want to bother sending data to a client if its the same...
    if ([_data isEqualToData:data]) return;
    
    _data = data;
    
    // Update clients
    [self _updateAllClientData];
}

- (void)start
{
    // Setup sockets.
    //
    // TODO: Setup IPv6 sockaddr_in as well.
    //
    int fdIPV4 = socket(AF_INET, SOCK_STREAM, 0);
        
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_len = sizeof(sin);
    sin.sin_port = 0;
    
    // Make sure we reuse addresses
    int x = 1;
    setsockopt(fdIPV4, SOL_SOCKET, SO_REUSEADDR, (void *)&x, sizeof(x));
    
    // Bind
    if (bind(fdIPV4, (const struct sockaddr *)&sin, sin.sin_len) != kCFSocketSuccess) {
        [self.delegate server:self didFailToStartWithError:[NSError errorWithDomain:RFServerErrorDomain code:RFServerFailedBindError userInfo:nil]];
        return;
    }
    
    socklen_t sinLen = sizeof(sin);
    if (getsockname(fdIPV4, (struct sockaddr *)&sin, &sinLen) != kCFSocketSuccess) {
        [self.delegate server:self didFailToStartWithError:[NSError errorWithDomain:RFServerErrorDomain code:RFServerFailedGetSocketNameError userInfo:nil]];
        return;
    }
    
    // Listen
    if (listen(fdIPV4, 10) != kCFSocketSuccess) {
        [self.delegate server:self didFailToStartWithError:[NSError errorWithDomain:RFServerErrorDomain code:RFServerFailedListenError userInfo:nil]];
        return;
    }
    
    // GO GO GO
    CFSocketContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
    CFSocketRef socketRef;
    CFRunLoopSourceRef runLoopRef;
    
    socketRef = CFSocketCreateWithNative(NULL, fdIPV4, kCFSocketAcceptCallBack, ListeningSocketCallBack, &context);
    runLoopRef = CFSocketCreateRunLoopSource(NULL, socketRef, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopRef, kCFRunLoopCommonModes);
    
    CFRelease(runLoopRef);
    CFRelease(socketRef);
    
    self.socketDescriptor = fdIPV4;
    
    // Setup Bonjour network discovery
    [self _registerBonjourServiceWithPort:sin.sin_port];
}

- (void)stop
{
    // Stop the bonjour service.
    if (self.bonjourNetService) {
        [self.bonjourNetService stop];
    }
    
    // Disconnect all clients
    [self.connectedServices enumerateObjectsUsingBlock:^(RFConnectedService *service, NSUInteger idx, BOOL *stop) {
        [service disconnect];
    }];
    
    // Close the socket
    close(self.socketDescriptor);
    self.socketDescriptor = 0;
    
    _running = NO;
}

#pragma mark - Private

- (void)_registerBonjourServiceWithPort:(in_port_t)port
{
    NSString *type = [NSString stringWithFormat:@"%@._tcp.", self.type];
    
    self.bonjourNetService = [[NSNetService alloc] initWithDomain:@"" type:type name:self.name port:ntohs(port)];
    self.bonjourNetService.delegate = self;
    [self.bonjourNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.bonjourNetService publish];
}

- (NSStream *)_setupAndOpenStream:(NSStream *)stream
{
    stream.delegate = self;
    [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [stream open];
    return stream;
}

- (void)_connectSocket:(int)socket toInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;
{
    NSUInteger socketIndex = [self.connectedServices indexOfObjectPassingTest:^BOOL(RFConnectedService *service, NSUInteger idx, BOOL *stop) {
        if (service.socketDescriptor == socket) {
            return YES;
        }
        return NO;
    }];
    
    // Make sure to close the streams if the socket descriptors are already in use.
    if (socketIndex != NSNotFound) {
        RFConnectedService *service = self.connectedServices[socketIndex];
        [service.inputStream close];
        [service.outputStream close];
        [self.connectedServices removeObjectAtIndex:socketIndex];
    }
    
    RFConnectedService *newService = [[RFConnectedService alloc] init];
    newService.socketDescriptor = socket;
    newService.inputStream = (NSInputStream *)[self _setupAndOpenStream:inStream];
    newService.outputStream = (NSOutputStream *)[self _setupAndOpenStream:outStream];
    
    [self.connectedServices addObject:newService];
}

- (void)_updateAllClientData
{
    [self.connectedServices enumerateObjectsUsingBlock:^(RFConnectedService *service, NSUInteger idx, BOOL *stop) {
        // All we have to do is write the length of the data to the client, and they'll get back to us with the checkmark.
        // Then we'll send the actual data.
        
        [self _updateClientData:service];
    }];
}

- (void)_updateClientData:(RFConnectedService *)service
{
    // Make sure that the client entered the passcode if there's one set.
    if ([self.passcode length] > 0 && !service.enteredPasscode) return;
    //
    // TODO: Add compression feature using zlib.
    //
    // Mac:
    //  sizeof(NSUInteger) = 8 ; NSUInteger actually `unsigned long`
    //  sizeof(uint64_t)   = 8
    //
    // iOS:
    //  sizeof(NSUInteger) = 4 ; NSUInteger actually `unsigned int`
    //  sizeof(uint64_t)   = 8
    //
    // Communication between devices means we need to stick to one size.
    // Using uint64_t (unsigned long long) for both.
    
    uint64_t length = [self.data length];
    
    // Make sure we actually have data to send...
    if (length == 0) return;
    
    // Setup a packet to send to the client.
    NSMutableData *packet = [[NSMutableData alloc] init];
    uint8_t header = RFServerSendingDataInformation;
    
    [packet appendBytes:&header length:sizeof(uint8_t)];
    [packet appendBytes:(const void *)&length length:sizeof(uint64_t)];
    
    [service.outputStream write:[packet bytes] maxLength:[packet length]];
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    if (_flags.respondsToDidFailBonjour) {
        [self.delegate server:self didFailToStartBonjourWithError:[NSError errorWithDomain:errorDict[NSNetServicesErrorDomain] code:[errorDict[NSNetServicesErrorCode] integerValue] userInfo:errorDict]];
    }
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    // For some reason -netServiceDidPublish: will never be called, so will is the best we get.
    _running = YES;
    
    if (_flags.respondsToDidStartBonjour) {
        [self.delegate serverDidStartBonjourService:self];
    }
}

#pragma mark - NSStream

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    // Get the service that is paired with this stream.
    NSUInteger index = [self.connectedServices indexOfObjectPassingTest:^BOOL(RFConnectedService *obj, NSUInteger idx, BOOL *stop) {
        if ([aStream isKindOfClass:[NSInputStream class]] && obj.inputStream == aStream) {
            return YES;
        }
        if ([aStream isKindOfClass:[NSOutputStream class]] && obj.outputStream == aStream) {
            return YES;
        }
        return NO;
    }];
    
    RFConnectedService *service = nil;
    if (index != NSNotFound) {
        service = self.connectedServices[index];
    }
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            // Connected the output stream.
            // Make sure that if the server has a passcode on it, that we tell the client.
            if ([aStream isKindOfClass:[NSOutputStream class]]) {
                NSOutputStream *outputStream = (NSOutputStream *)aStream;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    if ([self.passcode length] > 0) {
                        uint8_t packet = RFServerRequiresPasscode;
                        [outputStream write:&packet maxLength:sizeof(uint8_t)];
                    } else {
                        [self _updateClientData:service];
                    }
                });
            }
            break;
        }
        
        case NSStreamEventErrorOccurred: {
            // Uh-ohs...
            NSLog(@"NSStreamEventErrorOccurred: %@", aStream.streamError);
            break;
        }
            
        case NSStreamEventEndEncountered: {
            // Client disconnected abruptly?
            if (index != NSNotFound) {
                [service disconnect];
                [self.connectedServices removeObjectAtIndex:index];
            } else {
                // Kinda confused.. rouge stream? Oh well, close it.
                [aStream close];
                [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            }
            break;
        }
            
        case NSStreamEventHasBytesAvailable: {
            if ([aStream isKindOfClass:[NSInputStream class]]) {
                // Don't know who's stream this is but its not in memory...
                if (index == NSNotFound) return;
                
                // Read
                uint8_t buf[1024];
                NSInteger bytesRead = [(NSInputStream *)aStream read:buf maxLength:1024];
                
                if (bytesRead > 0) {
                    uint8_t packetHeader = buf[0];
                    switch (packetHeader) {
                            
                        case RFClientSendingPasscode: {
                            uint64_t length = *(uint64_t *)&buf[1];
                            NSString *readString = [[NSString alloc] initWithBytes:&buf[1+sizeof(uint64_t)] length:length encoding:NSUTF8StringEncoding];
                            
                            if ([readString isEqualToString:self.passcode]) {
                                service.enteredPasscode = YES;
                                [self _updateClientData:service];
                            } else {
                                uint8_t header = RFServerReceivedInvalidPasscode;
                                [service.outputStream write:&header maxLength:sizeof(uint8_t)];
                            }
                            break;
                        }
                            
                        case RFClientSendingOK: {
                            if ([self.passcode length] > 0 && !service.enteredPasscode) return;
                            
                            // Setup bytes pointer.
                            const void *bytes = [self.data bytes];
                            NSUInteger length = [self.data length];
                            
                            // Begin to send chunks of 1 KB data.
                            NSInteger sent = 0;
                            uint8_t header = RFServerBeginSendingData;
                            NSMutableData *packet = [[NSMutableData alloc] init];
                            
                            for (NSUInteger i = 0; i < length; i += sent) {
                                [packet setLength:0];
                                if (i == 0) {
                                    [packet appendBytes:&header length:sizeof(uint8_t)];
                                    [packet appendBytes:bytes length:MIN(1023, length - i)];
                                } else {
                                    [packet appendBytes:bytes length:MIN(1024, length - i)];
                                }
                                
                                sent = [service.outputStream write:[packet bytes] maxLength:[packet length]];
                                if (i == 0) {
                                    sent -= 1;
                                }
                                
                                // Pointer magic.
                                bytes += sent;
                            }
                            
                            break;
                        }
                            
                        case RFClientDisconnecting:
                            [service disconnect];
                            [self.connectedServices removeObjectAtIndex:index];
                            break;
                    }
                }
            }
            break;
        }
            
        // Shut the compiler up.
        default: break;
    }
}

#pragma mark - Callback

static void ListeningSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    int fd = *(const int *)data;
    RFServer *server = (__bridge RFServer *)info;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    CFStreamCreatePairWithSocket(NULL, fd, &readStream, &writeStream);
    
    inputStream = CFBridgingRelease(readStream);
    outputStream = CFBridgingRelease(writeStream);
    
    [inputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    [outputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    
    [server _connectSocket:fd toInputStream:inputStream outputStream:outputStream];
}

@end
