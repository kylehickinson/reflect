//
//  RFRootViewController.h
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-14.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFClient.h"

@interface RFRootViewController : UIViewController <RFClientDelegate>

- (void)resumeNetworking;
- (void)stopNetworking;

@end
