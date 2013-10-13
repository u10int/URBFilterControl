//
//  URBFilterControl.m
//  EpicSupportLibrary
//
//  Created by Nicholas Shipes on 7/9/13.
//  Copyright (c) 2013 Polaris Industries. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "URBFilterControl.h"

#define LEFT_OFFSET 25
#define RIGHT_OFFSET 25

@interface URBFilterControlButton : UIButton
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) CGFloat strokeWidth;
@end

@interface URBFilterControl	()
@property (nonatomic, strong) URBFilterControlButton *controlButton;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, assign) CGSize intervalSize;
@property (nonatomic, assign) CGRect barRegion;
@property (nonatomic, copy) URBFilterControlBlock handlerBlock;
- (void)initialize;
- (void)itemSelected:(UIGestureRecognizer *)recognizer;
- (CGPoint)centerForIndex:(NSInteger)index;
- (void)animateButtonToIndex:(NSInteger)index;
- (void)animateTitleAtIndex:(NSInteger)index selected:(BOOL)selected;
- (void)handleButtonPress:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleButtonPan:(UIGestureRecognizer *)gestureRecognizer;
@end

static CGSize const kURBDefaultSize = {300.0f, 70.0f};

@implementation URBFilterControl {
	BOOL _positionButton;
	BOOL _buttonPressed;
	NSInteger _selectedTitleIndex;
	struct {
		CGRect bar;
	} layout;
}

- (id)initWithTitles:(NSArray *)titles {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		self.titles = titles;
		[self initialize];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		CGRect nibFrame = self.frame;
		[self initialize];
		
		// restore nib settings
		self.frame = nibFrame;
	}
	return self;
}

- (void)initialize {
	self.backgroundColor = [UIColor clearColor];
	self.frame = CGRectMake(0.0, 0.0, kURBDefaultSize.width, kURBDefaultSize.height);
	
	_barBackgroundColor = [UIColor colorWithWhite:0.6 alpha:1.0];
	_barWidth = 5.0;
	
	_titleFont = [UIFont boldSystemFontOfSize:12.0];
	_titleColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	_selectedTitleColor = [UIColor colorWithRed:0.771 green:0.000 blue:0.017 alpha:1.000];
	
	_buttonSize = 26.0;
	_buttonMargin = 3.0;
	_buttonBackgroundColor = [UIColor colorWithRed:0.771 green:0.000 blue:0.017 alpha:1.000];
	_buttonStrokeColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	_buttonStrokeWidth = 2.0;
	_positionButton = YES;
	_buttonPressed = NO;
	self.animatesLabel = YES;
	
	self.controlButton = [URBFilterControlButton buttonWithType:UIButtonTypeCustom];
	self.controlButton.frame = CGRectMake(0, 0, self.buttonSize, self.buttonSize);
	self.controlButton.backgroundColor = self.buttonBackgroundColor;
	self.controlButton.strokeColor = self.buttonStrokeColor;
	self.controlButton.strokeWidth = self.buttonStrokeWidth;
	self.controlButton.adjustsImageWhenHighlighted = NO;
	[self addSubview:self.controlButton];
	
	UILongPressGestureRecognizer *buttonPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPress:)];
	buttonPressRecognizer.minimumPressDuration = 0.1;
	buttonPressRecognizer.allowableMovement = 20.0;
	buttonPressRecognizer.delegate = self;
	[self addGestureRecognizer:buttonPressRecognizer];
	
	// add labels
	CGFloat neededButtonSize = self.buttonSize + self.buttonMargin * 2.0;
	CGFloat labelWidth = neededButtonSize + 10.0;
	NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity:[self.titles count]];
	[self.titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, 25.0)];
		label.backgroundColor = [UIColor clearColor];
		label.text = title;
		label.font = self.titleFont;
		label.textColor = self.titleColor;
		label.lineBreakMode = NSLineBreakByTruncatingMiddle;
		label.adjustsFontSizeToFitWidth = YES;
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		
		[labels addObject:label];
	}];
	
	self.labels = [[NSArray alloc] initWithArray:labels];
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(itemSelected:)];
	[self addGestureRecognizer:tapRecognizer];
	
	UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
	panRecognizer.delegate = self;
	[self addGestureRecognizer:panRecognizer];
}

#pragma mark - Properties

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
	if (selectedIndex != _selectedIndex) {
		_selectedIndex = selectedIndex;
		[self animateButtonToIndex:selectedIndex];
		
		if (self.animatesLabel) {
			[self animateTitleAtIndex:_selectedTitleIndex selected:NO];
			[self animateTitleAtIndex:selectedIndex selected:YES];
		}
		
		if (self.handlerBlock) {
			self.handlerBlock(_selectedIndex, self);
		}
	}
}

- (void)setHandlerBlock:(URBFilterControlBlock)handlerBlock {
	_handlerBlock = [handlerBlock copy];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGFloat neededButtonSize = self.buttonSize + self.buttonMargin * 2.0;
	CGFloat sideOffset = neededButtonSize / 2.0;
	CGFloat intervalWidth = floorf((CGRectGetWidth(self.bounds) - sideOffset * 2.0) / ([self.titles count] - 1));
	self.intervalSize = CGSizeMake(intervalWidth, 50.0);
	
	CGFloat barCenterY = roundf(CGRectGetHeight(self.bounds) - sideOffset);
	layout.bar = CGRectIntegral(CGRectMake(sideOffset, barCenterY - self.barWidth / 2.0, CGRectGetWidth(self.bounds) - sideOffset * 2.0, self.barWidth));
	
	// layout labels
	[self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
		CGPoint center = [self centerForIndex:idx];
		label.center = CGPointMake(center.x, CGRectGetHeight(self.bounds) - neededButtonSize - CGRectGetMidY(label.bounds));
	}];
	
	if (_positionButton) {
		self.controlButton.frame = CGRectMake(self.buttonMargin, barCenterY - self.buttonSize / 2.0, self.buttonSize, self.buttonSize);
		if ([self.labels count] > 0) {
			[self animateTitleAtIndex:0 selected:YES];
		}
		_positionButton = NO;
	}
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
//	UIColor *shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
//	CGSize shadowOffset = CGSizeMake(0.0, 1.0);
//	CGFloat shadowBlurRadius = 2;

	// bar
	UIBezierPath *barPath = [UIBezierPath bezierPathWithRect:layout.bar];
	[self.barBackgroundColor setFill];
	[barPath fill];
	
	// bar inner shadow
	// point inner shadow
//	CGRect barBorderRect = CGRectInset(barPath.bounds, -shadowBlurRadius, -shadowBlurRadius);
//	barBorderRect = CGRectOffset(barBorderRect, -shadowOffset.width, -shadowOffset.height);
//	barBorderRect = CGRectInset(CGRectUnion(barBorderRect, barPath.bounds), -1, -1);
//	
//	UIBezierPath* barNegativePath = [UIBezierPath bezierPathWithRect: barBorderRect];
//	[barNegativePath appendPath: barPath];
//	barNegativePath.usesEvenOddFillRule = YES;
//	
//	CGContextSaveGState(context);
//	{
//		CGFloat xOffset = shadowOffset.width + round(barBorderRect.size.width);
//		CGFloat yOffset = shadowOffset.height;
//		CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
//									shadowBlurRadius, shadowColor.CGColor);
//		
//		[barPath addClip];
//		CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(barBorderRect.size.width), 0);
//		[barNegativePath applyTransform: transform];
//		[[UIColor grayColor] setFill];
//		[barNegativePath fill];
//	}
//	CGContextRestoreGState(context);
	
	
	// intervals
	CGFloat pointSize = self.buttonSize + self.buttonMargin * 2.0;
	// point base
	UIBezierPath *pointPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, CGRectGetMidY(layout.bar) - pointSize / 2.0, pointSize, pointSize)];
	[self.barBackgroundColor setFill];
	
	CGContextSaveGState(context);
	[self.titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {		
		CGContextTranslateCTM(context, (idx == 0) ? 0 : self.intervalSize.width, 0);
		[pointPath fill];
		
		// point inner shadow
//		CGRect ovalBorderRect = CGRectInset(pointPath.bounds, -shadowBlurRadius, -shadowBlurRadius);
//		ovalBorderRect = CGRectOffset(ovalBorderRect, -shadowOffset.width, -shadowOffset.height);
//		ovalBorderRect = CGRectInset(CGRectUnion(ovalBorderRect, pointPath.bounds), -1, -1);
//		
//		UIBezierPath* ovalNegativePath = [UIBezierPath bezierPathWithRect: ovalBorderRect];
//		[ovalNegativePath appendPath: pointPath];
//		ovalNegativePath.usesEvenOddFillRule = YES;
//		
//		CGContextSaveGState(context);
//		{
//			CGFloat xOffset = shadowOffset.width + round(ovalBorderRect.size.width);
//			CGFloat yOffset = shadowOffset.height;
//			CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
//										shadowBlurRadius, shadowColor.CGColor);
//			
//			[pointPath addClip];
//			CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(ovalBorderRect.size.width), 0);
//			[ovalNegativePath applyTransform: transform];
//			[[UIColor grayColor] setFill];
//			[ovalNegativePath fill];
//		}
//		CGContextRestoreGState(context);
	}];
	CGContextRestoreGState(context);
}

#pragma mark - Private

- (void)itemSelected:(UIGestureRecognizer *)recognizer {
	NSInteger selectedIndex = [self indexForPoint:[recognizer locationInView:self]];
	if (selectedIndex >= 0) {
		self.selectedIndex = selectedIndex;
	}
}

- (NSInteger)indexForPoint:(CGPoint)point {
	// index will be based on our label widths
	__block NSInteger index = -1;
	[self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
		CGRect rect = CGRectMake(CGRectGetMinX(label.frame), CGRectGetMinY(label.frame),
								 CGRectGetWidth(label.bounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(label.frame));
		if (CGRectContainsPoint(rect, point)) {
			index = idx;
			*stop = YES;
		}
	}];
	
	return index;
}

- (NSInteger)closestIndexForPoint:(CGPoint)point {
	NSInteger index = roundf((point.x - CGRectGetMinX(layout.bar)) / self.intervalSize.width);
	index = MIN(index, [self.titles count] - 1);
	
	return index;
}

- (CGPoint)centerForIndex:(NSInteger)index {
	return CGPointMake(roundf(CGRectGetMinX(layout.bar) + self.intervalSize.width * index), CGRectGetMidY(layout.bar));
}

- (void)handleButtonPress:(UIGestureRecognizer *)gestureRecognizer {
	CGPoint touchPoint = [gestureRecognizer locationInView:self];
	UIView *view = [self hitTest:touchPoint withEvent:nil];
	
	if (view == self.controlButton) {
		if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
			[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				self.controlButton.transform = CGAffineTransformMakeScale(1.3, 1.3);
			} completion:^(BOOL finished) {
				_buttonPressed = YES;
			}];
		}
		else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
			[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				self.controlButton.transform = CGAffineTransformIdentity;
			} completion:^(BOOL finished) {
				_buttonPressed = NO;
			}];
		}
	}
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)gestureRecognizer {
	if (_buttonPressed) {
		CGPoint touchPoint = [gestureRecognizer locationInView:self];
		if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged) {
			CGPoint p1 = self.controlButton.center;
			CGPoint p2 = touchPoint;
			if (p2.x >= CGRectGetMinX(layout.bar) && p2.x <= CGRectGetMaxX(layout.bar)) {
				self.controlButton.center = CGPointMake(p2.x, p1.y);
			}
		}
		else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
			NSInteger index = [self closestIndexForPoint:touchPoint];
			if (index >= 0) {
				CGPoint indexCenter = [self centerForIndex:index];
				[self animateTitleAtIndex:index selected:YES];
				[UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
					self.controlButton.center = indexCenter;
				} completion:^(BOOL finished) {
					_selectedIndex = index;
					if (self.handlerBlock) {
						self.handlerBlock(_selectedIndex, self);
					}
				}];
			}
		}
	}
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return YES;
}

- (void)animateButtonToIndex:(NSInteger)index {
	CGPoint targetCenter = [self centerForIndex:index];
	
	self.controlButton.transform = CGAffineTransformIdentity;
	[UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		self.controlButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.controlButton.transform = CGAffineTransformMakeScale(0.3, 0.3);
			self.controlButton.alpha = 0.0;
		} completion:^(BOOL finished) {
			self.controlButton.center = targetCenter;
			[UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				self.controlButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
				self.controlButton.alpha = 1.0;
			} completion:^(BOOL finished) {
				[UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
					self.controlButton.transform = CGAffineTransformIdentity;
				} completion:nil];
			}];
		}];
	}];
}

- (void)animateTitleAtIndex:(NSInteger)index selected:(BOOL)selected {
	UILabel *previousLabel;
	UILabel *currentLabel = [self.labels objectAtIndex:index];
	if (_selectedTitleIndex >= 0) {
		previousLabel = [self.labels objectAtIndex:_selectedTitleIndex];
	}
	
	if (currentLabel == previousLabel) return;
	
	[UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		if (previousLabel) {
			previousLabel.transform = CGAffineTransformIdentity;
			previousLabel.textColor = self.titleColor;
		}
		currentLabel.transform = CGAffineTransformMakeTranslation(0.0, -5.0);
		currentLabel.textColor = self.selectedTitleColor;
	} completion:^(BOOL finished) {
		_selectedTitleIndex = index;
	}];
}

@end


#pragma mark - URBFilterControlButton

@implementation URBFilterControlButton

- (void)drawRect:(CGRect)rect {
	//CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGFloat strokeWidth = self.strokeWidth;
	UIColor *outerColor = self.strokeColor;
	UIColor *innerColor = self.backgroundColor;
	
	// outer circle
	UIBezierPath* outerPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect))];
	[outerColor setFill];
	[outerPath fill];
	
	// inner circle
	UIBezierPath* innerPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(outerPath.bounds, strokeWidth, strokeWidth)];
	[innerColor setFill];
	[innerPath fill];
}

@end