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
	@autoreleasepool {
		[svg_render_context prepareRender:MIN(xScale, yScale)];
		rendered = svg_render(svgPrivate, &cocoa_svg_engine, (__bridge void *)(svg_render_context));
		[svg_render_context finishRender];
	}
	
	if (rendered == SVG_STATUS_SUCCESS) {
		CGContextDrawLayerInRect(CGCtx, rect, svg_render_context.renderLayer);
	}
}

- (void)dealloc
{
	if (svgPrivate) {
		svg_destroy(svgPrivate);
	}
}

- (void)setData:(NSData *)data
{
	svg_t *tmpSVG = NULL;
	
	svg_create(&tmpSVG);
	svg_status_t status = svg_parse_buffer(tmpSVG, [data bytes], [data length]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(tmpSVG);
		return;
	} else {
		if (svgPrivate) {
			svg_destroy(svgPrivate);
			svgPrivate = NULL;
		}
		svgPrivate = tmpSVG;
		[self setNeedsDisplay];
	}
}

- (void)setSVGFilePath:(NSString *)path
{
	svg_t *tmpSVG = NULL;
	
	svg_create(&tmpSVG);
	svg_status_t status = svg_parse(tmpSVG, [path fileSystemRepresentation]);
	if (status != SVG_STATUS_SUCCESS) {
		svg_destroy(tmpSVG);
		return;
	}else {
		if (svgPrivate) {
			svg_destroy(svgPrivate);
			svgPrivate = NULL;
		}
		svgPrivate = tmpSVG;
		[self setNeedsDisplay];
	}
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
