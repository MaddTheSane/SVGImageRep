//
//  SVGRenderContext.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#include <ApplicationServices/ApplicationServices.h>

#include <svg.h>

@class SVGRenderState, NSMutableArray;

extern svg_render_engine_t cocoa_svg_engine;

@interface SVGRenderContext : NSObject
{
@public
	CGLayerRef renderLayer;
	CGLayerRef unsizedRenderLayer;
	NSSize size;
	BOOL hasSize;
	
	double scale;
	
	SVGRenderState *current;
	NSMutableArray *states;
}

@property (readwrite, retain) SVGRenderState *current;
@property (readwrite, retain) NSMutableArray *states;
@property (readonly) NSSize size;
@property (readwrite) double scale;
@property (readonly) CGLayerRef renderLayer;

- (void)prepareRender:(double)a_scale;
- (void)finishRender;

- (double)lengthToPoints: (svg_length_t *)l;

+ (CGGradientRef)gradientFromSVGGradient:(svg_gradient_t *)gradient;

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
- (svg_status_t)renderText: (const char *)utf8;
- (svg_status_t)renderEllipse: (svg_length_t *)cx : (svg_length_t *)cy
							 : (svg_length_t *)rx : (svg_length_t *)ry;

@end
