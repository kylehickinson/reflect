//
//  RFPulseActivityViewIndicator.m
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-26.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFPulseActivityViewIndicator.h"
#import <QuartzCore/QuartzCore.h>

#define kRFAnimationDuration 1.2f

@interface RFPulseActivityViewIndicator ()

@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, assign) CGRect originalRect;
@property (nonatomic, assign) CGPoint originalCenter;

- (void)_animationLoop;

@end

@implementation RFPulseActivityViewIndicator

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.color = [UIColor blackColor];
        self.clipsToBounds = NO;
        self.alpha = 0.0;
    }
    return self;
}

- (void)setCenter:(CGPoint)center
{
    [super setCenter:center];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self.color setFill];
    CGContextFillEllipseInRect(ctx, rect);
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.originalCenter = self.center;
}

- (void)beginAnimating
{
    if (self.animationTimer) {
        [self stopAnimating];
    }
    
    self.originalCenter = self.center;
    self.originalRect = self.bounds;
    // Give it slightly longer time then the animation just to have a little delay between each complete render.
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:kRFAnimationDuration+0.2 target:self selector:@selector(_animationLoop) userInfo:nil repeats:YES];
    [self.animationTimer fire];
}

- (void)stopAnimating
{
    [self.animationTimer invalidate];
}

- (void)_animationLoop
{
    // Cheating a bit and using both the UIView block animation and CAKeyframeAnimations.
    //
    // This is because animating the opacity is easier and simpler to just use keyframe
    // animations, while the animation on scaling the circle is simple enough using
    // default UIView block animations.
    CAKeyframeAnimation *opacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacity.keyTimes = @[ @0.0f, @0.5f, @1.0f ];
    opacity.values = @[ @0.0f, @0.5f, @0.0f ];
    opacity.duration = kRFAnimationDuration;
    
    [self.layer addAnimation:opacity forKey:@"pulse"];
    
    self.bounds = CGRectZero;
    [UIView animateWithDuration:kRFAnimationDuration animations:^{
        self.bounds = self.originalRect;
        self.center = self.originalCenter;
    }];
}

@end
