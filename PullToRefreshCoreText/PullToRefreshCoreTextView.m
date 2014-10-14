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

        [self setBackgroundColor:[UIColor grayColor]];
        
        self.pullText = pullText;
        self.pullTextColor = pullTextColor;
        self.pullTextFont = pullTextFont;
        
        self.refreshingText = refreshingText;
        self.refreshingTextColor = refreshingTextColor;
        self.refreshingTextFont = refreshingTextFont;
        
        self.action = action;
        self.status = PullToRefreshCoreTextStatusNatural;

        
        self.textLayer = [CAShapeLayer layer];
        [self.textLayer setPath:[[pullText bezierPathWithFont:pullTextFont] CGPath]];
        [self.textLayer setFillColor:[[UIColor clearColor] CGColor]];
        [self.textLayer setStrokeColor:[pullTextColor CGColor]];
        [self.textLayer setLineWidth:1];
        [self.textLayer setSpeed:0];
        [self.layer addSublayer:self.textLayer];

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

- (void)updateState {
    
}

- (void)startLoading {
    CGFloat contentInset = self.scrollView.contentInset.top;
    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset+CGRectGetHeight(self.frame), 0, 0, 0);

    
    self.action ();
}

- (void)endLoading {
    self.status = PullToRefreshCoreTextStatusNatural;
    [self.textLayer setTimeOffset:0];
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }];
}


#pragma mark - Pulling

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"]) {
        if (self.status != PullToRefreshCoreTextStatusLoading) {
            CGFloat offset = self.scrollView.contentOffset.y + self.scrollView.contentInset.top;
            if (offset <= 0.0) {
                CGFloat startLoadingThreshold = self.frame.size.height;
                CGFloat fractionDragged       = -offset/startLoadingThreshold;
                
                [self.textLayer setTimeOffset:MIN(1, fractionDragged)];
//                self.textLayer.timeOffset = MAX(0.0, fractionDragged);

                if (fractionDragged >= 1.0) {
                    self.status = PullToRefreshCoreTextStatusLoading;
                    [self startLoading];
                }
            }
        }
    }
}


@end
