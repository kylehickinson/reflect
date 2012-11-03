//
//  RFImageViewController.h
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-27.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 The RFImageViewController is an image viewer for the images reflected to your
 iOS device.
 */
@interface RFImageViewController : UIScrollView <UIScrollViewDelegate>

/** The image that is showing in the view. */
@property (nonatomic, strong) UIImage *image;

/** 
 `YES` if the pulse indiciator view is visible and animating in the corner awaiting
 an image update.  `NO` otherwise.
 
 Defaults to `NO`.
 */
@property (nonatomic, assign) BOOL showImageUpdateActivityIndicator;

@end
