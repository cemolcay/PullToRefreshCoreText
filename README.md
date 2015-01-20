PullToRefreshCoreText
=====================

PullToRefresh extension for all UIScrollView type classes with animated text drawing style<br>

Demo
----

![alt tag](https://raw.githubusercontent.com/cemolcay/PullToRefreshCoreText/master/demo.gif)

Install
-------

**Manual**  
Copy the files in the folder named PullToRefreshCoreText to your project.  
Import the "UIScrollView+PullToRefreshCoreText.h"  
  
**Cocoapods**

```
    source 'https://github.com/CocoaPods/Specs.git'
    pod 'PullToRefreshCoreText', '~> 0.1'
``` 

Usage
-----

	- (void)addPullToRefreshWithPullText:(NSString *)pullText
	                       pullTextColor:(UIColor *)pullTextColor
	                        pullTextFont:(UIFont *)pullTextFont
	                      refreshingText:(NSString *)refreshingText
	                 refreshingTextColor:(UIColor *)refreshingTextColor
	                  refreshingTextFont:(UIFont *)refreshingTextFont
	                              action:(pullToRefreshAction)action;

It has 2 main texts, pulling and refreshing. <br>
Init function has parameters for creating this texts with its strings, text colors and fonts. <br> 
Last parameter is the block function where loading code goes to. <br>

Alternatively I added some other init methods if you want to use same texts or fonts etc. <br>

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


Implementation
--------------

    //Create ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.scrollView.frame.size.height + 1)];
    [self.view addSubview:self.scrollView];

    
    //add pull to refresh
    __weak typeof(self) weakSelf = self;
    [self.scrollView addPullToRefreshWithPullText:@"Pull To Refresh" pullTextColor:[UIColor blackColor] pullTextFont:DefaultTextFont refreshingText:@"Refreshing" refreshingTextColor:[UIColor blueColor] refreshingTextFont:DefaultTextFont action:^{
        [weakSelf loadItems];
    }];


One last thing: you should call the `[scrollView finishLoading]` method after the load finishes.<br>
Otherwise you stuck in refreshing state always.

Credits
=======

Blogs and codes I used for creating this<br>
https://github.com/jrturton/NSString-Glyphs<br>
http://www.codeproject.com/Articles/109729/Low-level-text-rendering<br>
http://ronnqvi.st/controlling-animation-timing/<br>
