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
	status = svg_parse_buffer(svg_test,[d bytes],[d length]);
	svg_destroy(svg_test);
	return status==SVG_STATUS_SUCCESS;
}


+ (NSImageRep *)imageRepWithData:(NSData *)d
{
	return [[self alloc] initWithData: d];
}


- (id)initWithData:(NSData *)d
{
	svg_status_t status;

	if (!(self=[super init]))
		return nil;

	svg_create(&svg);
	status = svg_parse_buffer(svg,[d bytes],[d length]);
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
		[self setSize: [svg_render_context size]];
	}

	return self;
}

- (void)dealloc
{
	svg_destroy(svg);
}

- (BOOL)draw
{
	SVGRenderContext *svg_render_context;
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
	CGContextRef CGCtx = (CGContextRef)[ctxt graphicsPort];

	CGAffineTransform ctm;

	ctm = CGContextGetCTM(CGCtx);
	
	svg_render_context = [[SVGRenderContext alloc] init];

	[svg_render_context prepareRender:
		sqrt(ctm.a * ctm.b + ctm.c * ctm.d)];
	svg_render(svg, &cocoa_svg_engine,  (__bridge void*)svg_render_context);
	[svg_render_context finishRender];

	/*DPScomposite(ctxt,
		0,0,svg_render_context->size.width,svg_render_context->size.height,
		[svg_render_context->result gState],0,0,NSCompositeSourceOver);*/
	


	return YES;
}

@end

extern void InitSVGImageRep()
{
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
}


@interface SVGImageRepDelegate : NSObject
@end

@implementation SVGImageRepDelegate

- (id)init
{
	self = [super init];
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
	return self;
}

@end

