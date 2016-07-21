/*
copyright 2003, 2004, 2005 Alexander Malmberg <alexander@malmberg.org>
*/

#include <math.h>
#include <tgmath.h>

#include <svg.h>
#import "SVGImageRep.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContext.h>
#include <CoreGraphics/CoreGraphics.h>

#import "SVGRenderContext.h"

@implementation SVGImageRep
{
	svg_t *svg;
}

+ (NSArray<NSString *> *)imageUnfilteredFileTypes
{
	static NSArray<NSString *> *types = nil;
	if (types == nil) {
		types = [[NSArray alloc] initWithObjects:@"svg", nil];
	}
	return types;
}

+ (NSArray<NSString *> *)imageUnfilteredTypes
{
	static NSArray<NSString *> *UTItypes = nil;
	if (UTItypes == nil) {
		UTItypes = [[NSArray alloc] initWithObjects:@"public.svg-image", nil];
	}
	return UTItypes;
}

+ (NSArray *)imageUnfilteredPasteboardTypes
{
	/* TODO: implement? */
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
	return [[self alloc] initWithData:d];
}

+ (NSImageRep *)imageRepWithContentsOfURL:(NSURL *)url
{
	return [[self alloc] initWithContentsOfURL:url];
}

+ (NSImageRep *)imageRepWithContentsOfFile:(NSString *)filename
{
	return [[self alloc] initWithContentsOfFile:filename];
}

- (instancetype)initWithSVGStruct:(svg_t*)anSVG
{
	if (self = [super init]) {
		if (anSVG == NULL) {
			return nil;
		}
		svg = anSVG;
		
		[self setColorSpaceName:NSCalibratedRGBColorSpace];
		[self setAlpha:YES];
		[self setBitsPerSample:NSImageRepMatchesDevice];
		[self setOpaque:NO];
		
		svg_length_t w, h;
		svg_get_size(svg, &w, &h);
		NSSize renderSize = NSMakeSize([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h]);
		[self setSize:renderSize];
		[self setPixelsHigh:NSImageRepMatchesDevice];
		[self setPixelsWide:NSImageRepMatchesDevice];
	}
	return self;
}

- (instancetype)initWithContentsOfFile:(NSString*)file
{
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:file]];
}

- (instancetype)initWithContentsOfURL:(NSURL *)d
{
	svg_t *tmpsvg;
	svg_status_t status;
	svg_create(&tmpsvg);
	status = svg_parse(tmpsvg, d.fileSystemRepresentation);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(tmpsvg);
		return [self initWithSVGStruct:NULL];
	}
	return [self initWithSVGStruct:tmpsvg];
}

- (instancetype)initWithData:(NSData *)d
{
	svg_t *tmpsvg;
	svg_status_t status;
	svg_create(&tmpsvg);
	status = svg_parse_buffer(tmpsvg, [d bytes], [d length]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(tmpsvg);
		return [self initWithSVGStruct:NULL];
	}
	return [self initWithSVGStruct:tmpsvg];
}

- (void)dealloc
{
	if (svg) {
		svg_destroy(svg);
	}
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
		rendered = svg_render(svg, &cocoa_svg_engine, (__bridge void *)(svg_render_context));
		[svg_render_context finishRender];
	}

	if (rendered == SVG_STATUS_SUCCESS) {
		NSSize renderSize = [self size];
		CGContextDrawLayerInRect(CGCtx, CGRectMake(0, 0, renderSize.width, renderSize.height), svg_render_context.renderLayer);
		didRender = YES;
	}
	return didRender;
}

+ (void)load
{
	[NSImageRep registerImageRepClass:[SVGImageRep class]];
}

@end
