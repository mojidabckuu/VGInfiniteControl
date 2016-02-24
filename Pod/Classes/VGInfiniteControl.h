//
//  VGInfiniteControl.h
//  SVPullToRefreshDemo
//
//  Created by Vlad Gorbenko on 2/24/16.
//  Copyright © 2016 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VGInfiniteControl : UIControl

@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, assign, readonly) BOOL isAnimating;

- (void)startAnimating;
- (void)stopAnimating;

@end
