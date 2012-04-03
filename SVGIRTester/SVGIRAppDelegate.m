//
//  SVGIRAppDelegate.m
//  SVGIRTester
//
//  Created by Charles Betts on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGIRAppDelegate.h"

@implementation SVGIRAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	NSBundle *SVGImageRepBundle;
	NSString *bundlesPath = [[NSBundle mainBundle] builtInPlugInsPath];
	SVGImageRepBundle = [[NSBundle alloc] initWithPath:[bundlesPath stringByAppendingPathComponent:@"SVGImageRep.bundle"]];
	BOOL loaded = [SVGImageRepBundle load];
	if (!loaded) {
		NSLog(@"Bundle Not loaded!");
		return;
	}
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSImage *tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-bug.svg"]];
	[svgBug setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-caution.svg"]];
	[svgCaution setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-important.svg"]];
	[svgImportant setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-note.svg"]];
	[svgNote setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-tip.svg"]];
	[svgTip setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-warning.svg"]];
	[svgWarning setImage:tempImage];
	[tempImage release]; tempImage = nil;

}

@end
