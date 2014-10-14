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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, 1000)];
    [self.view addSubview:scrollView];
    
    [scrollView addPullToRefreshWithPullText:@"Loading" action:^{
        NSLog(@"loading...");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
