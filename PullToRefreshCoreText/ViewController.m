//
//  ViewController.m
//  PullToRefreshCoreText
//
//  Created by Cem Olcay on 07/10/14.
//  Copyright (c) 2014 questa. All rights reserved.
//

#import "ViewController.h"
#import "UIScrollView+PullToRefreshCoreText.h"

@interface ViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, assign) NSInteger itemCount;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupScrollView];
}


#pragma mark - UIScrollView 

- (void)setupScrollView {
    self.contentHeight = 10;
    self.itemCount = 0;
    
    //Create ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.scrollView.frame.size.height + 10)];
    [self.view addSubview:self.scrollView];

    
    //add pull to refresh
    __weak typeof(self) weakSelf = self;
    [self.scrollView addPullToRefreshWithPullText:@"Pull To Refresh" action:^{
        [weakSelf loadItems];
    }];
    
    [self.scrollView addPullToRefreshWithPullText:@"Pull To Refresh" pullTextColor:[UIColor blackColor] pullTextFont:DefaultTextFont refreshingText:@"Pull To Refresh" refreshingTextColor:[UIColor blueColor] refreshingTextFont:DefaultTextFont action:^{
        [weakSelf loadItems];
    }];
    
    
    //add some items to scroll view
    for (int i = 0; i < 3; i++) {
        [self addNewItem];
    }
}

- (void)loadItems {
    __weak typeof(UIScrollView *) weakScrollView = self.scrollView;
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf addNewItem];
        [weakScrollView finishLoading];
    });
}

- (void)addNewItem {
    [self.scrollView addSubview:[self item]];
    
    if (self.scrollView.contentSize.height < self.contentHeight)
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.contentSize.width, self.contentHeight)];
}

- (UILabel *)item {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, self.contentHeight, self.view.frame.size.width - 20, 150)];
    [lbl setText:[NSString stringWithFormat:@"item %lu", self.itemCount++]];
    [lbl setTextAlignment:NSTextAlignmentCenter];
    [lbl setBackgroundColor:[self randomColor]];
    [lbl setFont:DefaultTextFont];

    self.contentHeight += 160;
    return lbl;
}

- (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

@end
