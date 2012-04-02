/*
copyright 2003, 2004, 2005 Alexander Malmberg <alexander@malmberg.org>
*/

#include <math.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSWindow.h>
#include <ApplicationServices/ApplicationServices.h>

#import "SVGImageRep.h"
#import "SVGRenderContext.h"

#include <svg.h>

@implementation SVGImageRep

+ (NSArray *)imageUnfilteredFileTypes
{
	return [NSArray arrayWithObject:@"svg"];
}

+ (NSArray *)imageUnfilteredTypes
{
	return [NSArray arrayWithObject:@"public.svg-image"];
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
	return [[self alloc] initWithData: d];
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
		svg_render(svg, &cocoa_svg_engine,  (__bridge void*)svg_render_context);
		[svg_render_context finishRender];
		NSSize renderSize = [svg_render_context size];
		[self setPixelsHigh:renderSize.height];
		[self setPixelsWide:renderSize.width];
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

	CGAffineTransform ctm = CGContextGetCTM(CGCtx);
	
	svg_render_context = [[SVGRenderContext alloc] init];

	[svg_render_context prepareRender:
		sqrt(ctm.a * ctm.b + ctm.c * ctm.d)];
	svg_render(svg, &cocoa_svg_engine, svg_render_context);
	[svg_render_context finishRender];

	NSSize renderSize = [svg_render_context size];
	CGContextDrawLayerInRect(CGCtx, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
	[svg_render_context release];
	return YES;
}

+ (void)load
{
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
}

@end

extern void InitSVGImageRep()
{
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
}
