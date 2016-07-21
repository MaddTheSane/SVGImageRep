/*
copyright 2003, 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include "SVGDocument.h"

#include <math.h>
#include <time.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSData.h>
#import <Foundation/NSError.h>
#import <Foundation/FoundationErrors.h>
#import <AppKit/NSGraphicsContext.h>

#include <svg.h>
#import "SVGRenderContext.h"

@implementation SVGView

- (void)setSVGRenderContext:(SVGRenderContext *)s
{
	if (s != svg) {
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
	
	if (svg) {
		NSSize SVGSize = [svg size];
		CGContextSetGrayFillColor(tempRef, 1.0, 1.0);
		CGContextFillRect(tempRef, CGRectMake(0, 0, SVGSize.width, SVGSize.height));
		CGContextDrawLayerInRect(tempRef, CGRectMake(0, 0, SVGSize.width, SVGSize.height), svg.renderLayer);
	}
}

@end

@interface SVGDocument ()
@property (readwrite, copy) NSData *documentData;
@end

@implementation SVGDocument
@synthesize documentData;

- (IBAction)reload:(id)sender
{
	svg_t *svg;
	
	svg_create(&svg);
	
	svg_status_t status = svg_parse_buffer(svg, [documentData bytes], [documentData length]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(svg);
		return;
	}
	NSRect scaledRect = NSZeroRect;
	{
		svg_length_t height, width;
		svg_get_size(svg, &width, &height);
		scaledRect.size = NSMakeSize([SVGRenderContext lengthToPoints:&width] * scale, [SVGRenderContext lengthToPoints:&height]*scale);
	}
	SVGRenderContext *svg_render_context = [[SVGRenderContext alloc] init];
	
	@autoreleasepool {
		[svg_render_context prepareRender: scale];
		status = svg_render(svg, &cocoa_svg_engine, (__bridge void *)(svg_render_context));
		[svg_render_context finishRender];
	}
	
	if (status != SVG_STATUS_SUCCESS) {
		svg_render_context = nil;
		svg_destroy(svg);
		return;
	}
	[svg_view setFrame:scaledRect];
	[svg_view setSVGRenderContext:svg_render_context];
	
	svg_destroy(svg);
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
	self.documentData = data;
	
	svg_destroy(svg);
	return YES;
}

#define SCALE(a,b) \
	- (IBAction)scale_##a##_##b:(id)sender \
	{ \
		scale=a##.##b; \
		[self reload:sender]; \
	}

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

