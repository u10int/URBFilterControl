//
//  URBFilterControl.h
//  EpicSupportLibrary
//
//  Created by Nicholas Shipes on 7/9/13.
//  Copyright (c) 2013 Polaris Industries. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URBFilterControl : UIControl <UIGestureRecognizerDelegate>

typedef void (^URBFilterControlBlock)(NSInteger selectedIndex, URBFilterControl *filterControl);

@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, strong) UIColor *barBackgroundColor;
@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *selectedTitleColor;
@property (nonatomic, strong) UIFont *titleFont;

@property (nonatomic, assign) CGFloat buttonSize;
@property (nonatomic, assign) CGFloat buttonMargin;
@property (nonatomic, assign) CGFloat buttonStrokeWidth;
@property (nonatomic, strong) UIColor *buttonBackgroundColor;
@property (nonatomic, strong) UIColor *buttonStrokeColor;

- (id)initWithTitles:(NSArray *)titles;
- (void)setHandlerBlock:(URBFilterControlBlock)handlerBlock;

@end
