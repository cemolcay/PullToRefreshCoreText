//
//  UIScrollView+PullToRefreshCoreText.h
//  PullToRefreshCoreText
//
//  Created by Cem Olcay on 07/10/14.
//  Copyright (c) 2014 questa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullToRefreshCoreTextView.h"

#define DefaultTextColor    [UIColor blackColor]
#define DefaultTextFont     [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:30]

@interface UIScrollView (PullToRefreshCoreText)

@property (nonatomic, strong) PullToRefreshCoreTextView *pullToRefreshView;

- (void)addPullToRefreshWithPullText:(NSString *)pullText
                              action:(pullToRefreshAction)action;

- (void)addPullToRefreshWithPullText:(NSString *)pullText
                      refreshingText:(NSString *)refreshingText
                              action:(pullToRefreshAction)action;

- (void)addPullToRefreshWithPullText:(NSString *)pullText
                                font:(UIFont *)font
                              action:(pullToRefreshAction)action;


- (void)addPullToRefreshWithPullText:(NSString *)pullText
                      refreshingText:(NSString *)refreshingText
                                font:(UIFont *)font
                              action:(pullToRefreshAction)action;


- (void)addPullToRefreshWithPullText:(NSString *)pullText
                       pullTextColor:(UIColor *)pullTextColor
                      refreshingText:(NSString *)refreshingText
                 refreshingTextColor:(UIColor *)refreshingTextColor
                                font:(UIFont *)font
                              action:(pullToRefreshAction)action;


- (void)addPullToRefreshWithPullText:(NSString *)pullText
                       pullTextColor:(UIColor *)pullTextColor
                        pullTextFont:(UIFont *)pullTextFont
                      refreshingText:(NSString *)refreshingText
                 refreshingTextColor:(UIColor *)refreshingTextColor
                  refreshingTextFont:(UIFont *)refreshingTextFont
                              action:(pullToRefreshAction)action;


- (void)finishLoading;


@end
