//
//  AppDelegate.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-13.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFRootViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) RFRootViewController *rootViewController;

@end
