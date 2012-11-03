//
//  RFImageViewController.m
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-27.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFImageViewController.h"
#import "RFPulseActivityViewIndicator.h"

@interface RFImageViewController ()

@property (nonatomic, strong) RFPulseActivityViewIndicator *pulseView;
@property (nonatomic, strong) UIImageView *imageView;

- (void)_doubleTap:(UITapGestureRecognizer *)tap;

@end

@implementation RFImageViewController

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
    }
    return _imageView;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        self.scrollsToTop = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.backgroundColor = [UIColor blackColor];
        self.bouncesZoom = YES;
        self.alwaysBounceVertical = YES;
        self.maximumZoomScale = 2.0f;
        
        self.imageView.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *_double = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_doubleTap:)];
        _double.numberOfTapsRequired = 2;
        [self.imageView addGestureRecognizer:_double];

        self.pulseView = [[RFPulseActivityViewIndicator alloc] initWithFrame:CGRectMake(20, self.frame.size.height-52, 32, 32)];
        self.pulseView.color = [UIColor whiteColor];
        [self addSubview:self.pulseView];
        
        self.showImageUpdateActivityIndicator = NO;
    }
    return self;
}

- (void)setShowImageUpdateActivityIndicator:(BOOL)showImageUpdateActivityIndicator
{
    _showImageUpdateActivityIndicator = showImageUpdateActivityIndicator;
    if (_showImageUpdateActivityIndicator) {
        [self.pulseView beginAnimating];
    } else {
        [self.pulseView stopAnimating];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    CGFloat scale = [UIScreen mainScreen].scale;
    
    self.imageView.frame = [self centeredFrameForScrollView:self andUIView:self.imageView];
    self.minimumZoomScale = MIN(self.frame.size.width / (self.imageView.image.size.width / scale), self.frame.size.height / (self.imageView.frame.size.height / scale));
    self.alwaysBounceHorizontal = self.minimumZoomScale < 1;
    self.contentSize = CGSizeMake(self.imageView.image.size.width / scale, self.imageView.image.size.height / scale);
    self.zoomScale = self.minimumZoomScale;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    
    self.imageView.frame = CGRectMake(0, 0, image.size.width / 2, image.size.height / 2);
    self.minimumZoomScale = MIN(self.frame.size.width / (self.imageView.image.size.width / scale), self.frame.size.height / (self.imageView.frame.size.height / scale));
    self.alwaysBounceHorizontal = self.minimumZoomScale < 1;
    self.contentSize = CGSizeMake(image.size.width / scale, image.size.height / scale);
    self.zoomScale = self.minimumZoomScale;
    self.imageView.frame = [self centeredFrameForScrollView:self andUIView:self.imageView];
}

#pragma mark - Private

- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
    CGSize boundsSize = scroll.bounds.size;
    CGRect frameToCenter = rView.frame;
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else {
        frameToCenter.origin.x = 0;
    }
    // center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else {
        frameToCenter.origin.y = 0;
    }
    return frameToCenter;
}

- (CGRect)zoomRectWithScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (void)_doubleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.zoomScale == 1.0 && self.imageView.image.size.width > self.frame.size.width) {
            [self zoomToRect:[self zoomRectWithScale:self.minimumZoomScale withCenter:[sender locationOfTouch:0 inView:self]] animated:YES];
        } else {
            [self zoomToRect:[self zoomRectWithScale:1.0 withCenter:[sender locationOfTouch:0 inView:self]] animated:YES];
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    self.imageView.frame = [self centeredFrameForScrollView:scrollView andUIView:self.imageView];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
