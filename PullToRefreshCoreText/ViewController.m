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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, 1000)];
    [self.view addSubview:self.scrollView];
    
    __weak typeof(self) weakSelf = self;
    [self.scrollView addPullToRefreshWithPullText:@"Loadddding" action:^{
        [weakSelf loadNewItems];
    }];
}

- (void)loadNewItems {
    __weak typeof(UIScrollView) *sc = self.scrollView;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [sc finishLoading];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
