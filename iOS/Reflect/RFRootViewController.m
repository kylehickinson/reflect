//
//  RFRootViewController.m
//  Reflect Client
//
//  Created by Kyle Hickinson on 2012-10-14.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

#import "RFRootViewController.h"
#import "RFPulseActivityViewIndicator.h"
#import "RFImageViewController.h"

@interface RFRootViewController ()

@property (nonatomic, strong) RFPulseActivityViewIndicator *pulsingCircle;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) RFImageViewController *imageView;

@property (nonatomic, strong) RFClient *client;

@end

@implementation RFRootViewController

- (void)_autosizeStatusLabel
{
    [self.statusLabel sizeToFit]; // Annoyingly this changes width too... bleh.
    self.statusLabel.frame = (CGRect){ self.statusLabel.frame.origin, self.view.bounds.size.width-40, self.statusLabel.frame.size.height };
}

- (id)init
{
    if ((self = [super init])) {
        self.client = [[RFClient alloc] initWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.bounds.size.width-40, 20)];
    self.titleLabel.text = @"IMAGE REFLECT";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.titleLabel.font = [UIFont fontWithName:@"Avenir-Black" size:18.0f];
    self.titleLabel.backgroundColor = self.view.backgroundColor;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.view.bounds.size.width-40, 0)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont fontWithName:@"Avenir-Book" size:16.0f];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    self.statusLabel.backgroundColor = self.view.backgroundColor;
    self.statusLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 20);
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [self _autosizeStatusLabel];
    
    self.pulsingCircle = [[RFPulseActivityViewIndicator alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    self.pulsingCircle.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.pulsingCircle.center = CGPointMake(self.view.center.x, self.view.center.y - 40);
    
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.pulsingCircle];
}

- (void)resumeNetworking
{
    [self.client searchForServices];
}

- (void)stopNetworking
{
    [self.pulsingCircle stopAnimating];
    [self _updateStatusLabelText:@""];
    
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    [self.client stop];
}

- (void)_updateStatusLabelText:(NSString *)text
{
    [UIView animateWithDuration:0.15 animations:^{
        self.statusLabel.alpha = 0.0f;
        self.statusLabel.frame = CGRectOffset(self.statusLabel.frame, 0, 30);
    } completion:^(BOOL finished) {
        self.statusLabel.text = text;
        self.statusLabel.frame = CGRectOffset(self.statusLabel.frame, 0, -60);
        [self _autosizeStatusLabel];
        
        [UIView animateWithDuration:0.15 animations:^{
            self.statusLabel.alpha = 1.0f;
            self.statusLabel.frame = CGRectOffset(self.statusLabel.frame, 0, 30);
        }];
    }];
}

#pragma mark - RFClientDelegate

- (void)client:(RFClient *)client didFindServices:(NSArray *)services
{
    if ([services count] == 0) return;
    
    if ([services count] > 1) {
        // Show a list to choose from.
        return;
    }
    
    NSNetService *service = services[0];
    [service resolveWithTimeout:0];
}

- (void)client:(RFClient *)client didConnectToService:(NSNetService *)service
{
    [self.client stopBrowsing];
    [self _updateStatusLabelText:[NSString stringWithFormat:@"Connected to %@\r\nWaiting for Data…", service.name]];
}

- (void)clientDidDisconnectFromService:(RFClient *)client
{
    [self _updateStatusLabelText:@""];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.imageView.frame = CGRectOffset(self.imageView.frame, 0, self.view.bounds.size.height);
    } completion:^(BOOL finished) {
        [self.imageView removeFromSuperview];
        self.imageView = nil;
    }];
    
    // Start search again, but give a second for the streams to close.
    [self.client performSelector:@selector(searchForServices) withObject:nil afterDelay:1.0f];
}

- (void)clientDidBeginBrowsing:(RFClient *)client
{
    [self.pulsingCircle beginAnimating];
    [self _updateStatusLabelText:@"Searching for Reflect Servers"];
}

- (void)client:(RFClient *)client willReceiveDataWithLength:(uint64_t)length
{
    [self _updateStatusLabelText:@"Receiving Data"];
    if (self.imageView.superview) {
        self.imageView.showImageUpdateActivityIndicator = YES;
    }
}

- (void)client:(RFClient *)client didRecieveData:(NSData *)data
{
    // Make sure we only take image data.
    UIImage *image = [UIImage imageWithData:data];
    if (image == nil) return;
    
    if (!self.imageView) {
        self.imageView = [[RFImageViewController alloc] initWithFrame:self.view.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.imageView];
        
        self.imageView.frame = CGRectOffset(self.imageView.frame, 0, self.imageView.bounds.size.height);        
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.frame = self.view.bounds;
        }];
    }
    
    self.imageView.showImageUpdateActivityIndicator = NO;
    self.imageView.image = image;
}

- (void)client:(RFClient *)client didUpdateServicesList:(NSArray *)services
{
    
}

- (void)serverRequiresPasscodeForClient:(RFClient *)client
{
    
}

- (void)client:(RFClient *)client passcodeWasInvalid:(NSString *)passcode
{
    
}

@end
