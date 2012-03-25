//
//  SVGViewer.m
//  SVGImageRep
//
//  Created by Charles Betts on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGViewer.h"
#import "Document.h"

@implementation SVGViewer

-(void) dealloc
{
	[super dealloc];
}

-(void) applicationWillFinishLaunching: (NSNotification *)n
{

}


-(void) applicationDidFinishLaunching: (NSNotification *)n
{
}


/*
 Action for opening a document. checks wether it's from the recent documents menu
 if not asks the user for a file name and then
 tells Document to open it. adds it to the defaults and the recent documents menu.
 */
- (IBAction)openSVGDocument:(id)sender
{
	NSOpenPanel *op;
	int i;
	NSArray *filenames;
	if ([sender representedObject])
	{
		[Document openFile: [sender representedObject]];
	}
	else
	{
	    op = [NSOpenPanel openPanel];
	    [op setTitle: @"Open svg file"];
	    [op setAllowsMultipleSelection: YES];
		[op setAllowedFileTypes:[NSArray arrayWithObject:@"public.svg-image"]];
	    [op setCanChooseDirectories: NO];
	    [op setCanChooseFiles: YES];
		
	    if ([op runModal]!=NSOKButton)
			return;
		filenames = [op filenames];
	    for (i=0;i < [filenames count]; i++)
		{
			NSString *filepath = [filenames objectAtIndex:i];
			[Document openFile: filepath];
		}
	}
}


@end
