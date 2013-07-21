//
//  AppDelegate.m
//  URBFilterControlDemo
//
//  Created by Nicholas Shipes on 7/9/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "AppDelegate.h"
#import "URBFilterControl.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	UIViewController *controller = [[UIViewController alloc] initWithNibName:nil bundle:nil];
	
	URBFilterControl *filterControl = [[URBFilterControl alloc] initWithTitles:@[@"Option 1", @"Option 2", @"Option 3"]];
	filterControl.frame = CGRectMake(50.0, 100.0, controller.view.bounds.size.width - 100.0, 70.0);
	[filterControl setHandlerBlock:^(NSInteger selectedIndex, URBFilterControl *filterControl) {
		NSLog(@"selected index: %i", selectedIndex);
	}];
	[controller.view addSubview:filterControl];
	self.window.rootViewController = controller;
	
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
