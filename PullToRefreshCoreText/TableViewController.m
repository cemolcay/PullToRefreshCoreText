//
//  TableViewController.m
//  PullToRefreshCoreText
//
//  Created by Codi Bonney on 12/3/15.
//  Copyright © 2015 questa. All rights reserved.
//

#import "TableViewController.h"
#import "UIScrollView+PullToRefreshCoreText.h"

static NSString* const KCellIdentifier = @"PTRCTTableCell";

@interface TableViewController ()
@property (nonatomic) NSMutableArray* datasource;
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.datasource = [NSMutableArray new];
    
    // TODO: add support for UIRectEdgeAll
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    //add pull to refresh
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithPullText:@"Pull To Refresh" pullTextColor:[UIColor blackColor] pullTextFont:DefaultTextFont refreshingText:@"Refreshing" refreshingTextColor:[UIColor blueColor] refreshingTextFont:DefaultTextFont action:^{
        [weakSelf loadItems];
    }];
    
    //add some items to scroll view
    for (int i = 0; i < 2; i++) {
        [self addNewItem];
    }    
}

- (void)loadItems {
    __weak typeof(UIScrollView *) weakScrollView = self.tableView;
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf addNewItem];
        [weakScrollView finishLoading];
    });
}

- (void)addNewItem {
    [self.datasource addObject:[self randomColor]];
    [self.tableView reloadData];
}

- (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

#pragma mark - UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:KCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:KCellIdentifier];
    }
    
    cell.textLabel.text = @(indexPath.row+1).stringValue;
    cell.backgroundColor = self.datasource[indexPath.row];
    
    return cell;
}


@end
