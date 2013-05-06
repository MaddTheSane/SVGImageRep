/*
copyright 2003, 2004, 2005 Alexander Malmberg <alexander@malmberg.org>
*/

#include <math.h>

#import "SVGImageRep.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContext.h>
#include <CoreGraphics/CoreGraphics.h>

#import "SVGRenderContext.h"

#include <svg.h>

@implementation SVGImageRep

+ (NSArray *)imageUnfilteredFileTypes
{
	static NSArray *types = nil;
	if (types == nil) {
		types = [[NSArray alloc] initWithObjects:@"svg", nil];
	}
	return types;
}

+ (NSArray *)imageUnfilteredTypes
{
	static NSArray *UTItypes = nil;
	if (UTItypes == nil) {
		UTItypes = [[NSArray alloc] initWithObjects:@"public.svg-image", nil];
	}
	return UTItypes;
}

+ (NSArray *)imageUnfilteredPasteboardTypes
{
	/* TODO */
	return nil;
}

+ (BOOL)canInitWithData:(NSData *)d
{
	svg_t *svg_test;
	svg_status_t status;
	svg_create(&svg_test);
	status = svg_parse_buffer(svg_test, [d bytes], [d length]);
	svg_destroy(svg_test);
	return status == SVG_STATUS_SUCCESS;
}

+ (NSImageRep *)imageRepWithData:(NSData *)d
{
	return [[[self alloc] initWithData:d] autorelease];
}

- (id)initWithData:(NSData *)d
{
	svg_status_t status;

	if (!(self = [super init]))
		return nil;

	svg_create(&svg);
	status = svg_parse_buffer(svg, [d bytes], [d length]);
	if (status != SVG_STATUS_SUCCESS)
	{
		[self autorelease];
		return nil;
	}

	[self setColorSpaceName:NSCalibratedRGBColorSpace];
	[self setAlpha:YES];
	[self setBitsPerSample:0];
	[self setOpaque:NO];

	{
		svg_length_t w, h;
		svg_get_size(svg, &w, &h);
		NSSize renderSize = NSMakeSize([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h]);
		[self setSize:renderSize];
#if CGFLOAT_IS_DOUBLE
		[self setPixelsHigh:ceil(renderSize.height)];
		[self setPixelsWide:ceil(renderSize.width)];
#else
		[self setPixelsHigh:ceilf(renderSize.height)];
		[self setPixelsWide:ceilf(renderSize.width)];
#endif
	}

	return self;
}

- (void)dealloc
{
	svg_destroy(svg);
	
	[super dealloc];
}

- (void)finalize
{
	svg_destroy(svg);
	
	[super finalize];
}

- (BOOL)draw
{
	SVGRenderContext *svg_render_context;
	CGContextRef CGCtx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	BOOL didRender = NO;
	svg_render_context = [[SVGRenderContext alloc] init];
	CGAffineTransform scaleTrans = CGContextGetCTM(CGCtx);

	svg_status_t rendered;
	@autoreleasepool {
		[svg_render_context prepareRender:MIN(scaleTrans.a, scaleTrans.d)];
		rendered = svg_render(svg, &cocoa_svg_engine, svg_render_context);
		[svg_render_context finishRender];
	}

	if (rendered == SVG_STATUS_SUCCESS) {
		NSSize renderSize = [self size];
		CGContextDrawLayerInRect(CGCtx, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
		didRender = YES;
	}
	[svg_render_context release];
	return didRender;
}

+ (void)load
{
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
}

@end
