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
		[SVGImageRepBundle release];
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
	[svgWarning setImage:[NSImage imageNamed:@"admon-warning"]];
	
	[SVGImageRepBundle release];
}

- (IBAction)selectSVG:(id)sender
{
	NSOpenPanel *op;
	op = [NSOpenPanel openPanel];
	[op setTitle: @"Open svg file"];
	[op setAllowsMultipleSelection: NO];
	[op setAllowedFileTypes:[NSArray arrayWithObjects:@"public.svg-image", @"svg", nil]];
	[op setCanChooseDirectories: NO];
	[op setCanChooseFiles: YES];
	
	if ([op runModal] != NSOKButton)
		return;
	NSURL *svgUrl = [[op URLs] objectAtIndex:0];

	NSImage *selectImage = [[NSImage alloc] initWithContentsOfURL:svgUrl];
	[svgSelected setImage:selectImage];
	[selectImage release];
}

@end
