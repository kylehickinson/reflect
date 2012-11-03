//
//  RFAppDelegate.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-15.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RFReflect.h"

@interface RFAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) RFReflect *reflect;
@property (strong) IBOutlet NSWindow *preferencesWindow;

- (IBAction)randomizePasscodeNow:(id)sender;

@end
