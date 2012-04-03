/*
copyright 2003, 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include "SVGDocument.h"

#include <math.h>
#include <time.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSData.h>
#import <AppKit/NSGraphicsContext.h>

#include <svg.h>
#import "SVGRenderContext.h"

@implementation SVGView

- (void)setSVGRenderContext:(SVGRenderContext *)s
{
	if(s != svg)
	{
		[svg release];
		[s retain];
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
	CGContextRef tempRef = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	
	if (svg)
	{
		NSSize SVGSize = [svg size];
		CGContextSetGrayFillColor(tempRef, 1.0, 1.0);
		CGContextFillRect(tempRef, CGRectMake(0, 0, SVGSize.width, SVGSize.height));
		CGContextDrawLayerInRect(tempRef, CGRectMake(0, 0, SVGSize.width, SVGSize.height), svg.renderLayer);
	}
}

- (void)dealloc
{
	[svg release];
	
	[super dealloc];
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
		svg_render(svg, &cocoa_svg_engine, svg_render_context);
		[svg_render_context finishRender];

		NSSize contextSize = [svg_render_context size];
		[svg_view setFrame:NSMakeRect(0, 0, contextSize.width, contextSize.height)];
		[svg_view setSVGRenderContext:svg_render_context];
		[svg_render_context release];

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
		if (outError != nil) {
			NSError *error =  [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
			*outError = error;
		}
		svg_destroy(svg);
		
		return NO;
	}
	documentData = [data copy];
	
	svg_destroy(svg);
	return YES;
}

- (void)dealloc
{
	[documentData release];
	
	[super dealloc];
}

#define SCALE(a,b) \
	- (IBAction)scale_##a##_##b:(id)sender \
	{ \
		scale=a##.##b; \
		[self reload:sender]; \
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
