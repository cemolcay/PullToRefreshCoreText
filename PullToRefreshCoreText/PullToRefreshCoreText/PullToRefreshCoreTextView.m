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
        
        self.triggerOffset = self.frame.size.height;
        self.triggerThreshold = self.frame.size.height;
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


- (CAShapeLayer *)pullTextLayer {
    CAShapeLayer *pull = [CAShapeLayer layer];
    [pull setPath:[[self.pullText bezierPathWithFont:self.pullTextFont] CGPath]];
    [pull setStrokeColor:[self.pullTextColor CGColor]];
    [pull setFillColor:[[UIColor clearColor] CGColor]];
    [pull setLineWidth:0.5];
    [pull setSpeed:0];
    
    float textSize = [self.pullText sizeWithAttributes:@{NSFontAttributeName:self.pullTextFont}].width;
    [pull setPosition:CGPointMake(pull.position.x + (self.frame.size.width-textSize)/2, 0)];
    
    
    CABasicAnimation *textAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [textAnimation setFromValue:@0];
    [textAnimation setToValue:@1];
    [textAnimation setDuration:1];
    [textAnimation setRemovedOnCompletion:NO];
    [pull addAnimation:textAnimation forKey:@"textAnimation"];
    
    return pull;
}

- (CATextLayer *)refreshingTextLayer {
    CATextLayer *text = [CATextLayer layer];
    [text setFrame:self.bounds];
    [text setString:(id)self.refreshingText];
    [text setFont:CTFontCreateWithName((__bridge CFStringRef)self.refreshingTextFont.fontName, self.refreshingTextFont.pointSize, NULL)];
    [text setFontSize:self.refreshingTextFont.pointSize];
    [text setForegroundColor:[self.refreshingTextColor CGColor]];
    [text setContentsScale:[[UIScreen mainScreen] scale]];
    
    float textSize = [self.refreshingText sizeWithAttributes:@{NSFontAttributeName:self.refreshingTextFont}].width;
    [text setPosition:CGPointMake(self.frame.size.width-textSize/2, 13)]; //center text in master layer
    
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.backgroundColor = [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3] CGColor];
    maskLayer.contents = (id)[[UIImage imageNamed:@"Mask.png"] CGImage];
    maskLayer.contentsGravity = kCAGravityCenter;
    maskLayer.frame = CGRectMake(self.frame.size.width * -1, 0.0f, self.frame.size.width * 2, self.frame.size.height);
    text.mask = maskLayer;
    
    CABasicAnimation *maskAnim = [CABasicAnimation animationWithKeyPath:@"position.x"];
    maskAnim.byValue = [NSNumber numberWithFloat:self.frame.size.width];
    maskAnim.repeatCount = HUGE_VALF;
    maskAnim.duration = 2.0f;
    [maskLayer addAnimation:maskAnim forKey:@"slideAnim"];
    
    return text;
}

#pragma mark - Interaction

- (void)scrollViewDidScroll:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged) {
        if (self.isLoading)
            return;
        
        CGFloat offset = self.scrollView.contentOffset.y + self.triggerThreshold;
        if (offset <= 0) {
            
            //animate pull text
            CGFloat fractionDragged = -offset/self.triggerOffset;
            [(CALayer *)[self.layer.sublayers firstObject] setTimeOffset:MIN(1, fractionDragged)];
            
            //update state
            if (fractionDragged >= 1) {
                self.status = PullToRefreshCoreTextStatusTriggered;
            } else {
                self.status = PullToRefreshCoreTextStatusDragging;
            }
            
        } else {
            self.status = PullToRefreshCoreTextStatusHidden;
        }
    }
    else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        if (self.status == PullToRefreshCoreTextStatusTriggered) {
            [self startLoading];
            
            [UIView animateWithDuration:0.2 animations:^{
                [self.scrollView setContentInset:UIEdgeInsetsMake(self.triggerOffset + self.triggerThreshold, 0, 0, 0)];
            }];
        } else {
            [(CALayer *)[self.layer.sublayers firstObject] setTimeOffset:0];
        }
    }
}


#pragma mark - Properties

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(scrollViewDidScroll:)];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    self.layer.sublayers = nil;
    if (loading) {
        [self.layer addSublayer:[self refreshingTextLayer]];
    } else {
        [self.layer addSublayer:[self pullTextLayer]];
    }
    
}

@end
