URBFilterControl
================

## Overview

`URBFilterControl` is a fully customizable UIControl subclass that offers an alternative method for displaying a series of filter options. This control can be used to select options that appear on a map view or within a table view listing.

![Screenshot of the sample project example](https://www.dropbox.com/s/je20bweeygon469/URBFilterControl_screenshot01.gif)

## Features

- Animatable button and label on selection
- Supports customizable colors and fonts
- Supports blocks for selected value changes
- Uses ARC and targets iOS 5.0+

## Installation

To use `URBFilterControl` in your own project:
- import `URBFilterControl.h` and `URBFilterControl.m` files into your project, and then include "`URBFilterControl.h`" where needed, or in your precompiled header
- link against the `QuartzCore` framework by adding `QuartzCore.framework` to your project under `Build Phases` > `Link Binary With Libraries`.

This project uses ARC and targets iOS 5.0+.

## Usage

(see a working example in the included sample project under /SampleProject)

The following is the most basic example of creating an URBFilterControl instance with the default configuration:

```objective-c
URBFilterControl *filterControl = [[URBFilterControl alloc] initWithTitles:@[@"Option 1", @"Option 2", @"Option 3"]];
filterControl.frame = CGRectMake(50.0, 100.0, self.view.bounds.size.width - 100.0, 70.0);
[filterControl setHandlerBlock:^(NSInteger selectedIndex, URBFilterControl *filterControl) {
	NSLog(@"selected index: %i", selectedIndex);
}];
[self.view addSubview:filterControl];
```

## Customization

Your `URBFilterControl` can be customized using the following properties:

```objective-c
@property (nonatomic, strong) UIColor *barBackgroundColor;			// default [UIColor colorWithWhite:0.6 alpha:1.0]
@property (nonatomic, assign) CGFloat barWidth;						// default 5.0f
@property (nonatomic, strong) UIColor *titleColor;					// default [UIColor colorWithWhite:0.5 alpha:1.0]
@property (nonatomic, strong) UIColor *selectedTitleColor;			// default [UIColor colorWithRed:0.771 green:0.000 blue:0.017 alpha:1.000]
@property (nonatomic, strong) UIFont *titleFont;					// default [UIFont boldSystemFontOfSize:12.0]

@property (nonatomic, assign) CGFloat buttonSize;					// default 26.0f (diameter)
@property (nonatomic, assign) CGFloat buttonMargin;					// default 3.0f
@property (nonatomic, assign) CGFloat buttonStrokeWidth;			// default 2.0f
@property (nonatomic, strong) UIColor *buttonBackgroundColor;		// default [UIColor colorWithRed:0.771 green:0.000 blue:0.017 alpha:1.000]
@property (nonatomic, strong) UIColor *buttonStrokeColor;			// default [UIColor whiteColor]

@property (nonatomic, assign) BOOL animatesLabel;					// default YES
```

## TODO

- Support using images instead of text labels for the options
- Support for customization using UIAppearance

## License

This code is distributed under the terms and conditions of the MIT license. Review the full [LICENSE](LICENSE) for all the details.

## Support/Contact

Think you found a bug or just have a feature request? Just [post it as an issue](https://github.com/u10int/URBFilterControl/issues), but make sure to review the existing issues first to avoid duplicates. You can also hit me up at [@u10int](http://twitter.com/u10int) for anything else, or to let me know how you're using this component. Thanks!