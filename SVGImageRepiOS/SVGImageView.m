//
//  SVGImageView.m
//  SVGImageRep
//
//  Created by Charles Betts on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGImageView.h"
#import "SVGRenderContext.h"
#include "svg.h"

@implementation SVGImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	SVGRenderContext *svg_render_context;
	CGContextRef CGCtx = UIGraphicsGetCurrentContext();
	svg_render_context = [[SVGRenderContext alloc] init];

	CGSize renderSize;
	{
		svg_length_t w, h;
		svg_get_size(svgPrivate, &w, &h);
		renderSize = CGSizeMake([SVGRenderContext lengthToPoints:&w], [SVGRenderContext lengthToPoints:&h]);
	}
	
	CGFloat xScale, yScale;
	xScale = rect.size.width / renderSize.width;
	yScale = rect.size.height / renderSize.height;
	
	svg_status_t rendered;
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		[svg_render_context prepareRender:MIN(xScale, yScale)];
		rendered = svg_render(svgPrivate, &cocoa_svg_engine, svg_render_context);
		[svg_render_context finishRender];
		[pool drain];
	}
	
	if (rendered == SVG_STATUS_SUCCESS) {
		CGContextDrawLayerInRect(CGCtx, rect, svg_render_context.renderLayer);
	}
	[svg_render_context release];

}

- (void)dealloc
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
	}
	
	[super dealloc];
}

- (void)finalize
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
	}
	
	[super finalize];
}

- (void)setData:(NSData *)data
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
		svgPrivate = NULL;
	}
	svg_create((svg_t **)&svgPrivate);
	svg_status_t status = svg_parse_buffer(svgPrivate, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(svgPrivate);
		svgPrivate = NULL;
		return;
	}
	[self setNeedsDisplay];
}

- (void)setSVGFilePath:(NSString *)path
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
		svgPrivate = NULL;
	}
	svg_create((svg_t **)&svgPrivate);
	svg_status_t status = svg_parse(svgPrivate, [path fileSystemRepresentation]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(svgPrivate);
		svgPrivate = NULL;
		return;
	}
	[self setNeedsDisplay];
}

- (void)setSVGFileURL:(NSURL *)url
{
	if ([url isFileURL]) {
		[self setSVGFilePath:[url path]];
	} else {
		[self setData:[NSData dataWithContentsOfURL:url]];
	}
}

@end
