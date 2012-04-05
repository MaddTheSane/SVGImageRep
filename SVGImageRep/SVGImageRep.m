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
#include <ApplicationServices/ApplicationServices.h>

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

	[self setColorSpaceName: NSCalibratedRGBColorSpace];
	[self setAlpha: YES];
	[self setBitsPerSample: 0];
	[self setOpaque: NO];

	/* TODO: figure out the size without actually rendering everything */
	{
		SVGRenderContext *svg_render_context = [[SVGRenderContext alloc] init];
		[svg_render_context prepareRender: 1.0];
		svg_render(svg, &cocoa_svg_engine, svg_render_context);
		[svg_render_context finishRender];
		NSSize renderSize = [svg_render_context size];
		[self setSize:renderSize];
		[self setPixelsHigh:renderSize.height];
		[self setPixelsWide:renderSize.width];
		[svg_render_context release];
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
	
	svg_render_context = [[SVGRenderContext alloc] init];

	[svg_render_context prepareRender:1.0];
	svg_render(svg, &cocoa_svg_engine, svg_render_context);
	[svg_render_context finishRender];

	NSSize renderSize = [svg_render_context size];
	CGContextDrawLayerInRect(CGCtx, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
	[svg_render_context release];
	return YES;
}

- (BOOL)drawInRect:(NSRect)rect
{
	SVGRenderContext *svg_render_context;
	CGContextRef CGCtx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		
	svg_render_context = [[SVGRenderContext alloc] init];
	
	CGFloat wScale, hScale;
	wScale = rect.size.width / [self pixelsWide];
	hScale = rect.size.height / [self pixelsHigh];
	
	[svg_render_context prepareRender:MIN(wScale, hScale)];
	svg_render(svg, &cocoa_svg_engine, svg_render_context);
	[svg_render_context finishRender];
	
	//NSSize renderSize = [svg_render_context size];
	CGContextDrawLayerInRect(CGCtx, NSRectToCGRect(rect), svg_render_context.renderLayer);
	[svg_render_context release];
	return YES;
}

+ (void)load
{
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
}

@end
