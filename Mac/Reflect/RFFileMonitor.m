//
//  RFFileMonitor.m
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-21.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFFileMonitor.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <fcntl.h>

NSString * const RFFileMonitorErrorDomain = @"RFFileMonitorErrorDomain";

@interface RFFileMonitor ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) int fileDescriptor;
@property (nonatomic, assign) int queue;
@property (nonatomic, strong) NSThread *monitoringThread;

@end

@implementation RFFileMonitor

- (void)beginMonitoringForPath:(NSString *)path
{
    if (self.queue > 0) {
        // Currently already watching a file...
        // I'm going to go ahead and just close it, maybe offer user a choice or just fail?
        [self stopMonitoring];
    }
    
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (_flags.respondsToFailedBegin) {
            [self.delegate fileMonitor:self failedToBeginMonitoringWithError:[NSError errorWithDomain:RFFileMonitorErrorDomain code:RFFileMonitorFileDoesntExistError userInfo:nil]];
        }
    }
    
    // File exists, but if its a directory we're opting out.  Though we could watch a directory using the FSEventStream's.
    if (isDirectory) {
        if (_flags.respondsToFailedBegin) {
            [self.delegate fileMonitor:self failedToBeginMonitoringWithError:[NSError errorWithDomain:RFFileMonitorErrorDomain code:RFFileMonitorFileIsDirectoryError userInfo:nil]];
        }
        return;
    }
    
    // Get the file descriptor.
    self.fileDescriptor = open([path UTF8String], O_EVTONLY);
    
    if (self.fileDescriptor < 0) {
        if (_flags.respondsToFailedBegin) {
            [self.delegate fileMonitor:self failedToBeginMonitoringWithError:[NSError errorWithDomain:RFFileMonitorErrorDomain code:RFFileMonitorFailedOpenError userInfo:nil]];
        }
        return;
    };
    
    // Now setup kqueue.
    self.path = path;
    self.queue = kqueue();
    if (self.queue < 0) {
        if (_flags.respondsToFailedBegin) {
            [self.delegate fileMonitor:self failedToBeginMonitoringWithError:[NSError errorWithDomain:RFFileMonitorErrorDomain code:RFFileMonitorQueueFailedError userInfo:nil]];
        }
        close(self.fileDescriptor);
        return;
    }
    
    // Start the monitoring thread, and we're off!
    self.monitoringThread = [[NSThread alloc] initWithTarget:self selector:@selector(_monitorInBackground) object:nil];
    [self.monitoringThread start];
    
    if (_flags.respondsToDidBeginMonitoring) {
        [self.delegate fileMonitor:self didBeginMonitoringPath:self.path];
    }
}

- (void)stopMonitoring
{
    close(self.fileDescriptor);
    close(self.queue);
    [self.monitoringThread cancel];
}

- (void)setDelegate:(id<RFFileMonitorDelegate>)delegate
{
    _delegate = delegate;
    memset(&_flags, 0, sizeof(_flags));
    
    if (_delegate) {
        _flags.respondsToDidBeginMonitoring = [_delegate respondsToSelector:@selector(fileMonitor:didBeginMonitoringPath:)];
        _flags.respondsToFailedBegin = [_delegate respondsToSelector:@selector(fileMonitor:failedToBeginMonitoringWithError:)]; 
    }
}

#pragma mark - Private

- (void)_monitorInBackground
{
	struct kevent change;
	struct kevent event;
    struct timespec timeout;
    
    // Setup kevent changes
	EV_SET(&change, self.fileDescriptor, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, NOTE_DELETE | NOTE_WRITE, 0, 0);
    
    // Setup timeout
    timeout.tv_sec = 0;
    timeout.tv_nsec = 500000000;
    
    // Register for events
    for (;;)
    {
        // Make sure we check if the thread was cancelled during each loop run.
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
        }
        
        if (kevent(self.queue, &change, 1, &event, 1, &timeout) != -1) {
            if (event.fflags & NOTE_WRITE || event.fflags & NOTE_DELETE) {
                [self.delegate fileMonitor:self pathDidChange:self.path];
            }
        }
    }
}

@end
