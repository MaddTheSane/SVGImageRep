//
//  SVGIRAppDelegate.h
//  SVGIRTester
//
//  Created by Charles Betts on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SVGIRAppDelegate : NSObject <NSApplicationDelegate>
{
	IBOutlet NSImageCell *svgBug;
	IBOutlet NSImageCell *svgCaution;
	IBOutlet NSImageCell *svgImportant;
	IBOutlet NSImageCell *svgNote;
	IBOutlet NSImageCell *svgTip;
	IBOutlet NSImageCell *svgWarning;
	IBOutlet NSImageCell *svgSelected;
	NSWindow *_window;
}
@property (assign) IBOutlet NSWindow *window;

- (IBAction)selectSVG:(id)sender;

@end
