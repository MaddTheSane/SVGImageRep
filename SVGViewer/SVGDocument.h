/*
copyright 2003 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef Document_h
#define Document_h

#import <AppKit/NSDocument.h>
#import <AppKit/NSView.h>

@class NSString,NSScrollView;
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

#define SCALESET(a,b) \
- (IBAction)scale_##a##_##b:(id)sender;

SCALESET(0,1)
SCALESET(0,25)
SCALESET(0,5)
SCALESET(0,75)
SCALESET(1,0)
SCALESET(1,5)
SCALESET(2,0)
SCALESET(3,0)
SCALESET(4,0)
SCALESET(5,0)


@end

#endif

