//
//  RFPulseActivityViewIndicator.h
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-26.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 The RFPulseActivityViewIndicator class reimplements a common activity view indiciator that
 is seen in Loren Brichter's Twitter for Mac.  Credits to him for an awesome
 animation that isn't boring like the default indicators.
 
 The only difference between the implementations is that RFPulsingCircle allows
 changing of the actual circle color by modifying the color property.
 */
@interface RFPulseActivityViewIndicator : UIView

/** @name Appearance */

/**
 The color of the pulsing indiciator.
 
 Defaults to the color black.
 */
@property (nonatomic, strong) UIColor *color;

/** @name Animation */

/** Begin animating the pulse indiciator. */
- (void)beginAnimating;

/** Stop the pulse indicators animation. */
- (void)stopAnimating;

@end
