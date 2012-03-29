//
//  SVGRenderContext.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#include <svg.h>
@class SVGRenderState, NSWindow, NSMutableArray;

extern svg_render_engine_t cocoa_svg_engine;

@interface SVGRenderContext : NSObject
{
@public
	NSWindow *__unsafe_unretained result;
	CGLayerRef renderLayer;
	NSSize size;
	
	double scale;
	
	SVGRenderState *current;
	NSMutableArray *states;
}

@property (readwrite) SVGRenderState *current;
@property (readwrite) NSMutableArray *states;
@property (unsafe_unretained, readonly) NSWindow *result;
@property (readonly) NSSize size;
@property (readwrite) double scale;
@property (readonly) CGLayerRef renderLayer;

- (void)prepareRender:(double)a_scale;
- (void)finishRender;

- (double)lengthToPoints: (svg_length_t *)l;


- (void)arcTo: (double)rx : (double) ry
			 : (double)x_axis_rotation
			 : (int)large_arc_flag
			 : (int)sweep_flag
			 : (double)x : (double)y;


- (svg_status_t)beginGroup: (double)opacity;
- (svg_status_t)endGroup: (double)opacity;

- (svg_status_t)setViewportDimension: (svg_length_t *)width :(svg_length_t *)height;
- (svg_status_t)applyViewbox: (svg_view_box_t)viewbox
							: (svg_length_t *)width : (svg_length_t *)height;

- (svg_status_t)renderRect: (svg_length_t *)x : (svg_length_t *)y
						  : (svg_length_t *)width : (svg_length_t *)height
						  : (svg_length_t *)rx : (svg_length_t *)ry;
- (svg_status_t)renderPath;
- (svg_status_t)renderText: (const unsigned char *)utf8;
- (svg_status_t)renderEllipse: (svg_length_t *)cx : (svg_length_t *)cy
							 : (svg_length_t *)rx : (svg_length_t *)ry;

@end
