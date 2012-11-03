//
//  RFReflect.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-14.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFServer.h"
#import "RFFileMonitor.h"

/**
 The RFReflect class is the view set up in the menu bar.
 From this view you'll be able to drag and drop files into it,
 as well as access preferences, quit, etc.
 */
@interface RFReflect : NSView <NSMenuDelegate, RFServerDelegate, RFFileMonitorDelegate>

/** The menu bar item */
@property (nonatomic, strong) NSStatusItem *statusItem;

/** @name Passcode */

/**
 Immediately updates the UI if the passcode was changed for any reason.
 
 Changing the passcode or enabling the passcode in preferences will automatically trigger
 this method if you plan to override it.
 */
- (void)updatePasscode;

/**
 Generates a randomized passcode which is 4 digits from 0-9 and sets it as the
 current passcode.
 */
- (void)randomizePasscode;

/** @name Selecting Files */

/**
 Select a file from a given path to begin reflecting to clients.
 
 @param path A path to a file.
 */
- (void)selectFileWithPath:(NSString *)path;

@end
