//
//  RFFileMonitor.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-21.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const RFFileMonitorErrorDomain;

/**
 An enumeration of errors that could appear in the fileMonitor:failedToBeginMonitoringWithError
 */
typedef enum : NSInteger {
    /**
     The file failed to open properly.
     */
    RFFileMonitorFailedOpenError = -200L,
    
    /**
     The path given was a directory, which is currently unsupported by RFFileMonitor
     */
    RFFileMonitorFileIsDirectoryError = -201L,
    
    /**
     The given path did not exist.
     */
    RFFileMonitorFileDoesntExistError = -202L,
    
    /**
     The call to kqueue() faliled.
     */
    RFFileMonitorQueueFailedError = -203L,
    
} RFFileMonitorErrorCode;

@class RFFileMonitor;

/**
 The file monitor delegate communicates when a path changed or when erorrs occur.
 */
@protocol RFFileMonitorDelegate<NSObject>
@required

/**
 A file under watch changed.
 
 @param fileMonitor The sender
 @param path The path of the file changed.
 */
- (void)fileMonitor:(RFFileMonitor *)fileMonitor pathDidChange:(NSString *)path;

@optional

/**
 An error occured while attempting to begin monitoring a file.
 
 @param fileMonitor The sender
 @param error The error that occured with the domain RFFileMonitorErrorDomain with possible codes in
 the RFFileMonitorErrorCode enumeration.
 */
- (void)fileMonitor:(RFFileMonitor *)fileMonitor failedToBeginMonitoringWithError:(NSError *)error;

/**
 The file monitor successfully began monitoring the file at path.
 
 @param fileMonitor The sender
 @param path The path to the file that is being monitored.
 */
- (void)fileMonitor:(RFFileMonitor *)fileMonitor didBeginMonitoringPath:(NSString *)path;

@end

/**
 The RFFileMonitor class allows the developer to watch a specific file for given changes.
 At the moment RFFileMonitor only allows watching 1 file at a time, but can be easily
 modified to watch multiple files if needed, or even directories using FSEvent APIs.
 */
@interface RFFileMonitor : NSObject {
    struct {
        unsigned respondsToFailedBegin:1;
        unsigned respondsToDidBeginMonitoring:1;
    } _flags;
}

/** The delegate */
@property (nonatomic, weak) id<RFFileMonitorDelegate> delegate;

/**
 Begin monitoring a file with a given path.
 
 @param path The path to the file to monitor.
 */
- (void)beginMonitoringForPath:(NSString *)path;

/**
 Stop monitoring the file that was originally watched after calling beginMonitoringForPath:
 */
- (void)stopMonitoring;

@end
