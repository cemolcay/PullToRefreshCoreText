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

        self.pullText = pullText;
        self.pullTextColor = pullTextColor;
        self.pullTextFont = pullTextFont;
        
        self.refreshingText = refreshingText;
        self.refreshingTextColor = refreshingTextColor;
        self.refreshingTextFont = refreshingTextFont;
        
        self.action = action;
        self.status = PullToRefreshCoreTextStatusHidden;
        self.loading = NO;
        
        self.triggerOffset = self.frame.size.height * 1.5;
    }
    return self;
}


#pragma mark - Logic

- (void)startLoading {
    [self setLoading:YES];
    self.action ();
}

- (void)endLoading {
    [self setLoading:NO];
    
    if (self.scrollView.contentInset.top > 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }];
    }
}

- (void)setupTextLayer {
    
    //init
    if (!self.textLayer) {
        self.textLayer = [CAShapeLayer layer];
        [self.textLayer setFillColor:[[UIColor clearColor] CGColor]];
        [self.textLayer setLineWidth:2];
        [self.textLayer setSpeed:0];
        [self.layer addSublayer:self.textLayer];
        
        CABasicAnimation *textAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        [textAnimation setFromValue:@0];
        [textAnimation setToValue:@1];
        [textAnimation setDuration:1];
        [textAnimation setRemovedOnCompletion:NO];
        [self.textLayer addAnimation:textAnimation forKey:@"textAnimation"];
    }

    //change values for pulling/refreshing
    if (self.isLoading) {
        float textSize = [self.refreshingText sizeWithAttributes:@{NSFontAttributeName:self.refreshingTextFont}].width;
        CGPoint textLayerPosition = CGPointMake(100, self.textLayer.position.y);
        [self.textLayer setPosition:textLayerPosition];
        
        [self.textLayer setPath:[[self.refreshingText bezierPathWithFont:self.refreshingTextFont] CGPath]];
        [self.textLayer setStrokeColor:[self.refreshingTextColor CGColor]];
        [self.textLayer setTimeOffset:1];
    } else {
        float textSize = [self.pullText sizeWithAttributes:@{NSFontAttributeName:self.pullTextFont}].width;
        CGPoint textLayerPosition = CGPointMake((self.frame.size.width-textSize)/2, self.textLayer.position.y);
        [self.textLayer setPosition:textLayerPosition];
        
        [self.textLayer setPath:[[self.pullText bezierPathWithFont:self.pullTextFont] CGPath]];
        [self.textLayer setStrokeColor:[self.pullTextColor CGColor]];
        [self.textLayer setTimeOffset:0];
    }
}

- (void)setupMaskLayer {

    if (self.isLoading) {
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
    } else {
        self.layer.mask = nil;
    }
}

#pragma mark - Pulling

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if([keyPath isEqualToString:@"contentOffset"]) {

        if (self.isLoading)
            return;
        
        CGFloat offset = self.scrollView.contentOffset.y + self.scrollView.contentInset.top;
        if (offset <= 0) {
            self.status = PullToRefreshCoreTextStatusDragging;
            
            CGFloat fractionDragged = -offset/self.triggerOffset;
            [self.textLayer setTimeOffset:MIN(1, fractionDragged)];
        } else {
            self.status = PullToRefreshCoreTextStatusHidden;
        }
    }
}

- (void)scrollViewPan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        
        CGFloat offset = self.scrollView.contentOffset.y + self.scrollView.contentInset.top;
        if (offset < -self.triggerOffset) {
            self.status = PullToRefreshCoreTextStatusTriggered;
            [self startLoading];
            
            [UIView animateWithDuration:0.2 animations:^{
                [self.scrollView setContentInset:UIEdgeInsetsMake(self.triggerOffset, 0, 0, 0)];
            }];
        }
    }
}


#pragma mark - Properties

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(scrollViewPan:)];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    [self setupTextLayer];
    [self setupMaskLayer];
}

@end
