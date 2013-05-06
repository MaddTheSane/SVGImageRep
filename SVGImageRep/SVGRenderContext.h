//
//  SVGRenderContext.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#include <CoreGraphics/CoreGraphics.h>
#if !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
#import <Foundation/NSGeometry.h>
#else
typedef CGSize NSSize;
#define NSSizeToCGSize(x) x
#define NSMakeSize CGSizeMake
#define NSEqualSizes CGSizeEqualToSize
#define NSZeroSize CGSizeZero
#endif

#include <svg.h>

#ifndef DEPRECATED_ATTRIBUTE
#if defined(__GNUC__) && ((__GNUC__ >= 4) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 1)))
#define DEPRECATED_ATTRIBUTE __attribute__((deprecated))
#else
#define DEPRECATED_ATTRIBUTE
#endif
#endif

@class SVGRenderState, NSMutableArray;

extern const svg_render_engine_t cocoa_svg_engine;

@interface SVGRenderContext : NSObject
{
@private
	CGLayerRef renderLayer;
	CGLayerRef unsizedRenderLayer;
	NSSize size;
	BOOL hasSize;
	
	double scale;
	
	SVGRenderState *current;
	NSMutableArray *states;
	int theIndent;
}

@property (readwrite, nonatomic, assign) SVGRenderState *current;
@property (readonly, nonatomic) NSMutableArray *states;
@property (readonly, nonatomic) NSSize size;
@property (readonly, nonatomic) double scale;
@property (readonly, nonatomic) CGLayerRef renderLayer;

- (void)prepareRender:(double)a_scale;
- (void)prepareRenderFromRenderContext:(SVGRenderContext *)prevContext;
- (void)finishRender;

- (void)setStrokeColor:(svg_color_t *)c alpha:(CGFloat)alph;
- (void)setFillColor:(svg_color_t *)c alpha:(CGFloat)alph;

- (double)lengthToPoints:(svg_length_t *)l;
+ (double)lengthToPoints:(svg_length_t *)l;

- (void)arcTo: (double)rx : (double) ry
			 : (double)x_axis_rotation
			 : (int)large_arc_flag
			 : (int)sweep_flag
			 : (double)x : (double)y;

- (svg_status_t)beginGroup: (double)opacity;
- (svg_status_t)endGroup: (double)opacity;

- (svg_status_t)setViewportDimension: (svg_length_t *)width :(svg_length_t *)height DEPRECATED_ATTRIBUTE;
- (svg_status_t)setViewportDimensionWidth: (svg_length_t *)width height:(svg_length_t *)height;

- (svg_status_t)applyViewbox: (svg_view_box_t)viewbox
							: (svg_length_t *)width : (svg_length_t *)height DEPRECATED_ATTRIBUTE;
- (svg_status_t)applyViewbox: (svg_view_box_t)viewbox withWidth: (svg_length_t *)width height: (svg_length_t *)height;


- (svg_status_t)renderRect: (svg_length_t *)x : (svg_length_t *)y
						  : (svg_length_t *)width : (svg_length_t *)height
						  : (svg_length_t *)rx : (svg_length_t *)ry DEPRECATED_ATTRIBUTE;
- (svg_status_t)renderRectWithX: (svg_length_t *)x y: (svg_length_t *)y
						  width: (svg_length_t *)width height: (svg_length_t *)height
						  rx: (svg_length_t *)rx ry: (svg_length_t *)ry;

- (svg_status_t)renderPath;
- (svg_status_t)renderText:(const char *)utf8 atX:(CGFloat)xPos y:(CGFloat)yPos;
- (svg_status_t)renderEllipse: (svg_length_t *)cx : (svg_length_t *)cy
							 : (svg_length_t *)rx : (svg_length_t *)ry DEPRECATED_ATTRIBUTE;
- (svg_status_t)renderEllipseWithCx: (svg_length_t *)cx cy:(svg_length_t *)cy rx:(svg_length_t *)rx ry:(svg_length_t *)ry;


@end
