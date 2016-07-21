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
	{
		NSURL *tempPath = [NSURL fileURLWithPath:[resourcePath stringByAppendingPathComponent:@"admon-important.svg"]];
		NSImageRep *imRep = [NSClassFromString(@"SVGImageRep") imageRepWithContentsOfURL:tempPath];
		tempImage = [[NSImage alloc] init];
		[tempImage addRepresentation:imRep];
	}
	[svgImportant setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"admon-note" withExtension:@"svg"]];
	[svgNote setImage:tempImage];
	[tempImage release]; tempImage = nil;
	tempImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"admon-tip" ofType:@"svg"]];
	[svgTip setImage:tempImage];
	[tempImage release]; tempImage = nil;
	[svgWarning setImage:[NSImage imageNamed:@"admon-warning"]];
	
	[SVGImageRepBundle release];
}

- (IBAction)selectSVG:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	op.title = @"Open SVG file";
	op.allowsMultipleSelection = NO;
	op.allowedFileTypes = @[@"public.svg-image", @"svg"];
	op.canChooseDirectories = NO;
	op.canChooseFiles = YES;
	
	if ([op runModal] != NSOKButton)
		return;
	NSURL *svgUrl = [[op URLs] objectAtIndex:0];

	NSImageRep *imRep = [NSClassFromString(@"SVGImageRep") imageRepWithContentsOfURL:svgUrl];
	NSImage *selectImage = [[NSImage alloc] init];
	[selectImage addRepresentation:imRep];
	[svgSelected setImage:selectImage];
	[selectImage release];
}

@end
