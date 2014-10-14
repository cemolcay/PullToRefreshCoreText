//
//  PullToRefreshCoreTextView.m
//  PullToRefreshCoreText
//
//  Created by Cem Olcay on 14/10/14.
//  Copyright (c) 2014 questa. All rights reserved.
//

#import "PullToRefreshCoreTextView.h"

@implementation PullToRefreshCoreTextView


#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
                     pullText:(NSString *)pullText
                pullTextColor:(UIColor *)pullTextColor
                 pullTextFont:(UIFont *)pullTextFont
               refreshingText:(NSString *)refreshingText
          refreshingTextColor:(UIColor *)refreshingTextColor
           refreshingTextFont:(UIFont *)refreshingTextFont
                       action:(pullToRefreshAction)action {
    if ((self = [super initWithFrame:frame])) {
        
        self.pullText = pullText;
        self.pullTextColor = pullTextColor;
        self.pullTextFont = pullTextFont;
        
        self.refreshingText = refreshingText;
        self.refreshingTextColor = refreshingTextColor;
        self.refreshingTextFont = refreshingTextFont;
        
        self.action = action;
        self.status = PullToRefreshCoreTextStatusNatural;
        
        [self setTextAlignment:NSTextAlignmentCenter];
        [self setBackgroundColor:[UIColor grayColor]];
        [self pullMode];
    }
    return self;
}

#pragma mark - Logic

- (void)updateState {
    
}


#pragma mark - Pulling

- (void)pullMode {
    
    [self setText:self.pullText];
    [self setFont:self.pullTextFont];
    [self setTextColor:self.pullTextColor];
}

- (void)refreshingMode {
    [self setText:self.refreshingText];
    [self setTextColor:self.refreshingTextColor];
    [self setFont:self.refreshingTextFont];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"contentOffset"])
    {
        NSLog(@"detect %@", NSStringFromCGPoint([[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]));
    }
}



@end
