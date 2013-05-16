//
//  SVGIRAppDelegate.m
//  SVGIRTester
//
//  Created by Charles Betts on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGIRAppDelegate.h"
#import "ARCBridge.h"

@implementation SVGIRAppDelegate

@synthesize window = _window;

#if 0
- (void)dealloc
{
    [super dealloc];
}
#endif

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	NSBundle *SVGImageRepBundle;
	NSURL *bundlesURL = [[NSBundle mainBundle] builtInPlugInsURL];
	SVGImageRepBundle = [[NSBundle alloc] initWithURL:[bundlesURL URLByAppendingPathComponent:@"SVGImageRep.bundle"]];
	BOOL loaded = [SVGImageRepBundle load];
	if (!loaded) {
		NSLog(@"Bundle Not loaded!");
		RELEASEOBJ(SVGImageRepBundle);
		return;
	}
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSImage *tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-bug.svg"]];
	[svgBug setImage:tempImage];
	RELEASEOBJ(tempImage); tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-caution.svg"]];
	[svgCaution setImage:tempImage];
	RELEASEOBJ(tempImage); tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-important.svg"]];
	[svgImportant setImage:tempImage];
	RELEASEOBJ(tempImage); tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-note.svg"]];
	[svgNote setImage:tempImage];
	RELEASEOBJ(tempImage); tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"admon-tip.svg"]];
	[svgTip setImage:tempImage];
	RELEASEOBJ(tempImage); tempImage = nil;
	[svgWarning setImage:[NSImage imageNamed:@"admon-warning"]];
	
	RELEASEOBJ(SVGImageRepBundle);
}

- (IBAction)selectSVG:(id)sender
{
	NSOpenPanel *op;
	op = [NSOpenPanel openPanel];
	[op setTitle: @"Open SVG file"];
	[op setAllowsMultipleSelection: NO];
	[op setAllowedFileTypes:[NSArray arrayWithObjects:@"public.svg-image", @"svg", nil]];
	[op setCanChooseDirectories: NO];
	[op setCanChooseFiles: YES];
	
	if ([op runModal] != NSOKButton)
		return;
	NSURL *svgUrl = [[op URLs] objectAtIndex:0];

	NSImage *selectImage = [[NSImage alloc] initWithContentsOfURL:svgUrl];
	[svgSelected setImage:selectImage];
	RELEASEOBJ(selectImage);
}

@end
