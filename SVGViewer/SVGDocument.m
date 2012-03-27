/*
copyright 2003, 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include "SVGDocument.h"

#include <math.h>
#include <time.h>

#import <Foundation/NSFileManager.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSWindow.h>

#include <svg.h>
#import "SVGRenderContext.h"

@implementation SVGView

- (void)setSVGRenderContext:(SVGRenderContext *)s
{
	if(s != svg)
	{
		svg = s;
	}
	[self setNeedsDisplay: YES];
}


- (BOOL)isOpaque
{
	return YES;
}

- (void)drawRect:(NSRect)r
{
	[super drawRect:r];
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];

	CGContextRef tempRef = (CGContextRef)[ctxt graphicsPort];
	
	if (svg)
	{
		NSSize SVGSize = [svg size];
		CGContextSetGrayFillColor(tempRef, 1.0, 1.0);
		CGContextFillRect(tempRef, CGRectMake(0, 0, SVGSize.width, SVGSize.height));
		
//		DPScomposite(ctxt,0,0,svg->size.width,svg->size.height,[svg->result gState],0,0,NSCompositeSourceOver);
	}
}

@end


@implementation SVGDocument

- (IBAction)reload:(id)sender
{
	{
		svg_t *svg;
		SVGRenderContext *svg_render_context = [[SVGRenderContext alloc] init];

		svg_create(&svg);
		svg_parse_buffer(svg, [documentData bytes], [documentData length]);

		[svg_render_context prepareRender: scale];
		svg_render(svg, &cocoa_svg_engine, (__bridge void*)svg_render_context);
		[svg_render_context finishRender];

		NSSize contextSize = [svg_render_context size];
		[svg_view setFrame:NSMakeRect(0, 0, contextSize.width, contextSize.height)];
		[svg_view setSVGRenderContext:svg_render_context];

		svg_destroy(svg);
	}
}

- (id)init
{
    self = [super init];
    if (self) {
		scale = 1.0;
    }
    return self;
}

- (NSString *)windowNibName
{
	return @"SVGDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	[self reload:nil];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	svg_t *svg;
	svg_create(&svg);

	svg_status_t status = svg_parse_buffer(svg, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		NSError *__autoreleasing error =  [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
		if (outError != nil) {
			outError = &error;
		}
		svg_destroy(svg);
		
		return NO;
	}
	documentData = [data copy];
	
	svg_destroy(svg);
	return YES;
}


#define SCALE(a,b) \
	- (IBAction)scale_##a##_##b:(id)sender \
	{ \
		scale=a##.##b; \
		[self reload: nil]; \
	} \


SCALE(0,1)
SCALE(0,25)
SCALE(0,5)
SCALE(0,75)
SCALE(1,0)
SCALE(1,5)
SCALE(2,0)
SCALE(3,0)
SCALE(4,0)
SCALE(5,0)

@end

