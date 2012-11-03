//
//  RFReflect.m
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-14.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFReflect.h"

@interface RFReflect ()

@property (nonatomic, strong) RFServer *server;

@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, assign) BOOL menuVisible;

@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, strong) NSImage *highlightedIcon;

@property (nonatomic, strong) RFFileMonitor *fileMonitor;
@property (nonatomic, copy) NSString *chosenPath;

- (void)_setup;
- (void)_updateRecentList;
- (void)_clearRecentList;
- (void)_selectFileFromMenu:(NSMenuItem *)sender;
- (NSMenuItem *)_recentFilesMenuItem;

@end

@implementation RFReflect

- (id)init
{
    if ((self = [super initWithFrame:NSMakeRect(0, 0, 28, 20)])) {
        [self _setup];
    }
    return self;
}

- (NSImage *)icon
{
    if (!_icon) {
        _icon = [NSImage imageNamed:@"temp-icon"];
    }
    return _icon;
}

- (NSImage *)highlightedIcon
{
    if (!_highlightedIcon) {
        _highlightedIcon = [NSImage imageNamed:@"temp-icon-highlighted"];
    }
    return _highlightedIcon;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.statusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:self.menuVisible];
    if (self.menuVisible) {
        [self.highlightedIcon drawAtPoint:NSMakePoint(4, 3) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    } else {
        [self.icon drawAtPoint:NSMakePoint(4, 3) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    self.menuVisible = YES;
    [self setNeedsDisplay:YES];
    [self.statusItem popUpStatusItemMenu:self.menu];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [self mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
}

- (void)menuDidClose:(NSMenu *)menu
{
    self.menuVisible = NO;
    [self setNeedsDisplay:YES];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSArray *propertyList = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    if ([propertyList count] == 0) {
        return NO;
    }
    
    NSString *path = propertyList[0];
    [self selectFileWithPath:path];
    
    return YES;
}

- (void)selectFileWithPath:(NSString *)path
{
    // Should probably add some error handling here...
    self.chosenPath = path;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.server.data = [NSData dataWithContentsOfFile:self.chosenPath];
    });
    
    NSUserDefaults *userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    
    if ([userDefaults boolForKey:@"watch-files"]) {
        [self.fileMonitor beginMonitoringForPath:self.chosenPath];
    }
    
    NSMutableArray *recents = [[userDefaults objectForKey:@"recent-files"] mutableCopy];
    
    NSInteger idx = [recents indexOfObjectIdenticalTo:path];
    if (idx != NSNotFound) {
        // Just move it to the top.
        [recents removeObjectAtIndex:idx];
    }
    
    // Add it to the top.  Keep max capacity at 5.
    [recents insertObject:path atIndex:0];
    if ([recents count] > 5) {
        [recents removeObjectsInRange:NSMakeRange(5, [recents count]-5)];
    }
    
    [userDefaults setObject:[NSArray arrayWithArray:recents] forKey:@"recent-files"];
    [self _updateRecentList];
}

#pragma mark - RFFileMonitorDelegate

- (void)fileMonitor:(RFFileMonitor *)fileMonitor pathDidChange:(NSString *)path
{
    self.server.data = [NSData dataWithContentsOfFile:path];
}

#pragma mark - RFServerDelegate

- (void)serverDidStartBonjourService:(RFServer *)server
{
    [[self.menu itemAtIndex:2] setTitle:@"Server is running"];
    [[self.menu itemAtIndex:3] setTitle:@"Stop"];
    
    // Register for drag events
    [self registerForDraggedTypes:@[ NSFilenamesPboardType ]];
}

- (void)updatePasscode
{
    NSDictionary *userDefaults = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] dictionaryRepresentation];
    
    NSString *passcode = [NSString stringWithFormat:@"%04d", [userDefaults[@"passcode"] intValue]];
    NSString *passcodeMenu = [NSString stringWithFormat:@"Passcode: %@", [userDefaults[@"passcode-enabled"] boolValue] ? passcode : @"None"];
    
    [[self.menu itemAtIndex:0] setTitle:passcodeMenu];
    
    self.server.passcode = [userDefaults[@"passcode-enabled"] boolValue] ? passcode : nil;
}

- (void)randomizePasscode
{
    int r[4] = {
        arc4random() % 10,
        arc4random() % 10,
        arc4random() % 10,
        arc4random() % 10
    };
    NSString *passcode = [NSString stringWithFormat:@"%d%d%d%d", r[0], r[1], r[2], r[3]];
    [[[NSUserDefaultsController sharedUserDefaultsController] defaults] setObject:[NSNumber numberWithInt:[passcode intValue]] forKey:@"passcode"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Only registered for passcode/passcode-enabled, so don't need to worry about checking keypaths.
    [self updatePasscode];
}

#pragma mark - Private

- (NSMenuItem *)_recentFilesMenuItem
{
    NSDictionary *userDefaults = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] dictionaryRepresentation];
    
    // Setup sub-menu for recent files
    NSMenuItem *recentFiles = [[NSMenuItem alloc] initWithTitle:@"Recent Files" action:nil keyEquivalent:@""];
    NSMenu *recentSubmenu = [[NSMenu alloc] init];
    
    NSArray *recent = userDefaults[@"recent-files"];
    if ([recent count] > 0) {
        [recent enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
            NSMenuItem *file = [[NSMenuItem alloc] initWithTitle:[path lastPathComponent] action:@selector(_selectFileFromMenu:) keyEquivalent:@""];
            file.target = self;
            file.tag = idx;
            [recentSubmenu addItem:file];
        }];
        [recentSubmenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *clearRecent = [[NSMenuItem alloc] initWithTitle:@"Clear" action:@selector(_clearRecentList) keyEquivalent:@""];
        clearRecent.target = self;
        [recentSubmenu addItem:clearRecent];
    } else {
        [recentSubmenu addItemWithTitle:@"No Recent Items" action:nil keyEquivalent:@""];
    }
    recentFiles.submenu = recentSubmenu;
    
    return recentFiles;
}

- (void)_selectFileFromMenu:(NSMenuItem *)sender
{
    NSDictionary *userDefaults = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] dictionaryRepresentation];
    
    [self selectFileWithPath:userDefaults[@"recent-files"][sender.tag]];
}

- (void)_updateRecentList
{
    NSInteger index = [self.menu indexOfItemWithTitle:@"Recent Files"];
    [self.menu removeItemAtIndex:index];
    [self.menu insertItem:[self _recentFilesMenuItem] atIndex:index];
}

- (void)_clearRecentList
{
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setObject:@[ ] forKey:@"recent-files"];
    
    [self _updateRecentList];
}

- (void)_toggleWatchFiles:(NSMenuItem *)sender
{
    sender.state = !sender.state;
    [[[NSUserDefaultsController sharedUserDefaultsController] defaults] setBool:sender.state forKey:@"watch-files"];
    
    if (sender.state == NSOnState && [self.chosenPath length] > 0) {
        [self.fileMonitor beginMonitoringForPath:self.chosenPath];
    } else {
        [self.fileMonitor stopMonitoring];
    }
}

- (void)_setup
{
    NSDictionary *userDefaults = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] dictionaryRepresentation];
    
    if ([userDefaults[@"passcode-randomize"] boolValue]) {
        // Randomize on launch!
        [self randomizePasscode];
    }
    
    // Make the status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setView:self];
    
    // Setup the menu
    self.menu = [[NSMenu alloc] init];
    self.menu.delegate = self;
    
    // Selectors target automatically is app-delegate and thats fine for most.
    [self.menu addItemWithTitle:@"Passcode:" action:nil keyEquivalent:@""];
    [self updatePasscode];
    
    
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItemWithTitle:@"Server is not running" action:nil keyEquivalent:@""];
    NSMenuItem *startStop = [[NSMenuItem alloc] initWithTitle:@"Start" action:@selector(_toggleServer) keyEquivalent:@""];
    startStop.target = self;
    [self.menu addItem:startStop];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:[self _recentFilesMenuItem]];
    
    NSMenuItem *watchFiles = [[NSMenuItem alloc] initWithTitle:@"Watch for Changes" action:@selector(_toggleWatchFiles:) keyEquivalent:@""];
    watchFiles.target = self;
    watchFiles.state = [userDefaults[@"watch-files"] boolValue];
    [self.menu addItem:watchFiles];
    
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItemWithTitle:@"Preferences…" action:@selector(_showPreferences:) keyEquivalent:@""];
    [self.menu addItemWithTitle:@"Quit" action:@selector(_quit) keyEquivalent:@""];
    
    // File monitoring
    self.fileMonitor = [[RFFileMonitor alloc] init];
    self.fileMonitor.delegate = self;
    
    // Start the server
    self.server = [[RFServer alloc] init];
    self.server.delegate = self;
    
    if ([userDefaults[@"server-start-on-launch"] boolValue]) {
        [self.server start];
    }
    
    // Gotta make sure we know when a user changes passcode prefs.
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.passcode" options:NSKeyValueObservingOptionInitial context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.passcode-enabled" options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)_toggleServer
{
    if (self.server.running) {
        [self.server stop];
        [[self.menu itemAtIndex:2] setTitle:@"Server is not running"];
        [[self.menu itemAtIndex:3] setTitle:@"Start"];
        [self unregisterDraggedTypes];
    } else {
        [[self.menu itemAtIndex:2] setTitle:@"Server is starting…"];
        [[self.menu itemAtIndex:3] setTitle:@"Stop"];
        [self.server start];
    }
}

@end
