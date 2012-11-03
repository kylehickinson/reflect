//
//  RFAppDelegate.m
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-15.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFAppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation RFAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *computerName = (__bridge NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);
    if (computerName == nil) {
        computerName = @"";
    }
    
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    
    // I should probably throw all these keys in a header file so I can stop trying to remember all of them...
    [defaults registerDefaults:@{
     @"server-start-on-launch" : @YES,
     @"passcode-enabled" : @NO,
     @"passcode" : @"",
     @"passcode-randomize" : @YES,
     @"passcode-simple" : @YES,
     @"bonjour-use-name" : @NO,
     @"bonjour-name" : computerName,
     @"bonjour-use-type" : @NO,
     @"bonjour-type" : @"_reflect",
     @"recent-files" : @[ ],
     @"watch-files" : @YES
     }];
    
    // (Maybe) Start Reflect server.
    self.reflect = [[RFReflect alloc] init];
}

- (void)randomizePasscodeNow:(id)sender
{
    [self.reflect randomizePasscode];
}

- (void)_showPreferences:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.preferencesWindow makeKeyAndOrderFront:nil];
}

- (void)_quit
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
