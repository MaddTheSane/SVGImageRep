/*
copyright 2003 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef Document_h
#define Document_h

#import <AppKit/NSDocument.h>
#import <AppKit/NSView.h>

@class NSString, NSData;
@class SVGRenderContext;

@interface SVGView : NSView
{
	SVGRenderContext *svg;
}

- (void)setSVGRenderContext:(SVGRenderContext *)s;

@end

@interface SVGDocument : NSDocument
{
	NSData *documentData;

	IBOutlet SVGView *svg_view;

	double scale;
}
- (IBAction)reload:(id)sender;

- (IBAction)scale_0_1:(id)sender;
- (IBAction)scale_0_25:(id)sender;
- (IBAction)scale_0_5:(id)sender;
- (IBAction)scale_0_75:(id)sender;
- (IBAction)scale_1_0:(id)sender;
- (IBAction)scale_1_5:(id)sender;
- (IBAction)scale_2_0:(id)sender;
- (IBAction)scale_3_0:(id)sender;
- (IBAction)scale_4_0:(id)sender;
- (IBAction)scale_5_0:(id)sender;

@end

#endif

