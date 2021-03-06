//
//  VGInfiniteControl.m
//  SVPullToRefreshDemo
//
//  Created by Vlad Gorbenko on 2/24/16.
//  Copyright © 2016 Home. All rights reserved.
//

#import "VGInfiniteControl.h"

static CGFloat const VGInfiniteControlHeight = 60;

typedef NS_ENUM(NSInteger, VGInfiniteControlState) {
    VGInfiniteControlStateStopped,
    VGInfiniteControlStateTriggered,
    VGInfiniteControlStateLoading,
    VGInfiniteControlStateAll
};

@interface VGInfiniteControl ()

@property (nonatomic, assign) VGInfiniteControlState infiniteState;

@property (nonatomic, readwrite) CGFloat originalBottomInset;

@property (nonatomic, assign) BOOL isObserving;

@property (nonatomic, weak) UIScrollView *scrollView;

@end

@implementation VGInfiniteControl

@synthesize activityIndicatorView = _activityIndicatorView;

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    CGRect adjustedFrame = frame;
    adjustedFrame.size.height = VGInfiniteControlHeight;
    // TODO: Whaaaat is 1.5???
    adjustedFrame.size.width = [[UIScreen mainScreen] bounds].size.width * 1.5;
    self = [super initWithFrame:adjustedFrame];
    if(self) {
        [self setup];
    }
    return self;
}

#pragma mark - Setup

- (void)setup {
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicatorView.hidesWhenStopped = YES;
    _activityIndicatorView.center = self.center;
    [self addSubview:_activityIndicatorView];
}

#pragma mark -

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!self.superview && newSuperview) {
        if([newSuperview isKindOfClass:[UIScrollView class]] && !self.scrollView) {
            self.scrollView = (UIScrollView *)newSuperview;
            self.originalBottomInset = self.scrollView.contentInset.bottom;
        }
        [self observeScrollView];
    }
}

- (void)didMoveToWindow {
    if(!self.window) {
        [self removeScrollViewObserve];
    } else {
        if(self.enabled) {
            [self observeScrollView];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(self.scrollView) {
        self.activityIndicatorView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
}

#pragma mark - Accessors

- (BOOL)isAnimating {
    return self.activityIndicatorView.isAnimating;
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset + VGInfiniteControlHeight;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark -

- (void)triggerRefresh {
    self.infiniteState = VGInfiniteControlStateTriggered;
    self.infiniteState = VGInfiniteControlStateLoading;
}

#pragma mark - Modifiers

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if(enabled) {
        [self observeScrollView];
    } else {
        [self removeScrollViewObserve];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.activityIndicatorView.color = tintColor;
}

- (void)setInfiniteState:(VGInfiniteControlState)infiniteState {
    if(_infiniteState == infiniteState) {
        return;
    }
    
    VGInfiniteControlState previousState = _infiniteState;
    _infiniteState = infiniteState;
    
    CGRect viewBounds = [self.activityIndicatorView bounds];
    CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
    [self.activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    
    switch (infiniteState) {
        case VGInfiniteControlStateStopped:
            [self.activityIndicatorView stopAnimating];
            break;
        case VGInfiniteControlStateTriggered:
        case VGInfiniteControlStateLoading:
            [self.activityIndicatorView startAnimating];
            break;
        default:
            [self.activityIndicatorView startAnimating];
    }
    
    if(previousState == VGInfiniteControlStateTriggered && infiniteState == VGInfiniteControlStateLoading && self.enabled) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

#pragma mark - Animation management

- (void)startAnimating {
    self.infiniteState = VGInfiniteControlStateLoading;
}

- (void)stopAnimating {
    self.infiniteState = VGInfiniteControlStateStopped;
}

#pragma mark - KV Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    } else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, [self contentSize].height, self.scrollView.bounds.size.width, VGInfiniteControlHeight);
    }
}

- (void)observeScrollView {
    if(!self.isObserving) {
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [self.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        [self setScrollViewContentInsetForInfiniteScrolling];
        self.isObserving = YES;
        self.frame = CGRectMake(0, [self contentSize].height, self.scrollView.bounds.size.width, VGInfiniteControlHeight);
        [self setNeedsLayout];
    }
}

- (void)removeScrollViewObserve {
    if(self.isObserving) {
        [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
        self.isObserving = NO;
        [self resetScrollViewContentInset];
    }
}

#pragma mark - Utils

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.infiniteState != VGInfiniteControlStateLoading && self.enabled) {
        CGFloat scrollViewContentHeight = [self contentSize].height;
        CGFloat scrollOffsetThreshold = scrollViewContentHeight-self.scrollView.bounds.size.height;
        
        if(!self.scrollView.isDragging && self.infiniteState == VGInfiniteControlStateTriggered) {
            self.infiniteState = VGInfiniteControlStateLoading;
        } else if(contentOffset.y > scrollOffsetThreshold && self.infiniteState == VGInfiniteControlStateStopped && self.scrollView.isDragging) {
            self.infiniteState = VGInfiniteControlStateTriggered;
        } else if(contentOffset.y < scrollOffsetThreshold  && self.infiniteState != VGInfiniteControlStateStopped) {
            self.infiniteState = VGInfiniteControlStateStopped;
        }
    }
}

// Table retrurns wrong contentSize in case when you have tableHeaderView or tableFooterView
- (CGSize)contentSize {
    if([self.scrollView isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *)self.scrollView;
        NSInteger rowsCount = [tableView.dataSource tableView:tableView numberOfRowsInSection:0];
        if(tableView.tableFooterView && !rowsCount) {
            CGSize size = CGSizeMake(tableView.contentSize.width, tableView.tableFooterView.frame.origin.y + tableView.tableFooterView.bounds.size.height);
            return size;
        }
        if(!rowsCount) {
            CGSize size = CGSizeMake(tableView.contentSize.width, tableView.tableHeaderView.bounds.size.height + tableView.tableFooterView.bounds.size.height);
            return size;
        }
    }
    return self.scrollView.contentSize;
}

@end
