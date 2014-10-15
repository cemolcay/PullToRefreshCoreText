//
//  PullToRefreshCoreTextView.m
//  PullToRefreshCoreText
//
//  Created by Cem Olcay on 14/10/14.
//  Copyright (c) 2014 questa. All rights reserved.
//

#import "PullToRefreshCoreTextView.h"

@implementation NSString (Glyphs)

-(UIBezierPath*)bezierPathWithFont:(UIFont*)font {
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:self attributes:[NSDictionary dictionaryWithObject:(__bridge id)ctFont forKey:(__bridge NSString*)kCTFontAttributeName]];
    CFRelease(ctFont);
    
    CGMutablePathRef letters = CGPathCreateMutable();
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributed);
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
    {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++)
        {
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            
            CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
            CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
            CGPathAddPath(letters, &t, letter);
            CGPathRelease(letter);
        }
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:letters];
    CGRect boundingBox = CGPathGetBoundingBox(letters);
    CGPathRelease(letters);
    CFRelease(line);
    
    // The path is upside down (CG coordinate system)
    [path applyTransform:CGAffineTransformMakeScale(1.0, -1.0)];
    [path applyTransform:CGAffineTransformMakeTranslation(0.0, boundingBox.size.height)];
    
    return path;
}

@end


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

        //[self setBackgroundColor:[UIColor grayColor]];
        
        self.pullText = pullText;
        self.pullTextColor = pullTextColor;
        self.pullTextFont = pullTextFont;
        
        self.refreshingText = refreshingText;
        self.refreshingTextColor = refreshingTextColor;
        self.refreshingTextFont = refreshingTextFont;
        
        self.action = action;
        self.status = PullToRefreshCoreTextStatusHidden;
        self.loading = NO;
                
        self.textLayer = [CAShapeLayer layer];
        [self.textLayer setPath:[[pullText bezierPathWithFont:pullTextFont] CGPath]];
        [self.textLayer setFillColor:[[UIColor clearColor] CGColor]];
        [self.textLayer setStrokeColor:[pullTextColor CGColor]];
        [self.textLayer setLineWidth:2];
        [self.textLayer setSpeed:0];
        [self.layer addSublayer:self.textLayer];
        
        float textSize = [pullText sizeWithAttributes:@{NSFontAttributeName:pullTextFont}].width;
        [self.textLayer setPosition:CGPointMake((self.frame.size.width-textSize)/2, self.textLayer.position.y)];

        self.pullAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        [self.pullAnimation setFromValue:@0];
        [self.pullAnimation setToValue:@1];
        [self.pullAnimation setDuration:1];
        [self.pullAnimation setRemovedOnCompletion:NO];
        
        [self.textLayer addAnimation:self.pullAnimation forKey:@"pullAnimation"];
    }
    return self;
}


#pragma mark - Logic

- (void)startLoading {
    [self setLoading:YES];
    
    if (!self.layer.mask)
    {
        self.maskLayer = [CALayer layer];
        self.maskLayer.backgroundColor = [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.25] CGColor];
        self.maskLayer.contents = (id)[[UIImage imageNamed:@"Mask.png"] CGImage];
        self.maskLayer.contentsGravity = kCAGravityCenter;
        self.maskLayer.frame = CGRectMake(self.frame.size.width * -1, 0.0f, self.frame.size.width * 2, self.frame.size.height);
        self.layer.mask = self.maskLayer;
        
        CABasicAnimation *maskAnim = [CABasicAnimation animationWithKeyPath:@"position.x"];
        maskAnim.byValue = [NSNumber numberWithFloat:self.frame.size.width];
        maskAnim.repeatCount = HUGE_VALF;
        maskAnim.duration = 2.0f;
        [self.maskLayer addAnimation:maskAnim forKey:@"slideAnim"];
    }
    
    self.action ();
}

- (void)endLoading {
    [self setLoading:NO];
    [self.textLayer setTimeOffset:0];
    
    self.layer.mask = nil;
    
    if (self.scrollView.contentInset.top > 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }];
    }
}


#pragma mark - Pulling

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if([keyPath isEqualToString:@"contentOffset"]) {

        if (self.isLoading)
            return;
        
        CGFloat offset = self.scrollView.contentOffset.y + self.scrollView.contentInset.top;
        CGFloat triggerOffset = self.frame.size.height;
        
        if (offset <= 0 && offset > -triggerOffset) {
            self.status = PullToRefreshCoreTextStatusDragging;
            
            CGFloat fractionDragged = -offset/triggerOffset;
            [self.textLayer setTimeOffset:MIN(1, fractionDragged)];
        }
        else if (offset < -triggerOffset) {
            self.status = PullToRefreshCoreTextStatusTriggered;
            [self startLoading];
        }
        else {
            self.status = PullToRefreshCoreTextStatusHidden;
        }
    } else if ([keyPath isEqualToString:@"isDragging"]) {
        NSLog(@"dragging change");
    }
}

- (void)scrollViewPan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        if (self.status == PullToRefreshCoreTextStatusTriggered) {
            [self.scrollView setContentInset:UIEdgeInsetsMake(self.frame.size.height, 0, 0, 0)];
        }
    }
}


#pragma mark - Properties

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(scrollViewPan:)];
}

@end
