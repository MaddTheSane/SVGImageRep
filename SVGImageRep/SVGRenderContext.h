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
	
	NSMutableArray<SVGRenderState*> *states;
	int theIndent;
}

@property (readonly, nonatomic) SVGRenderState *current;
@property (readonly, nonatomic) NSMutableArray<SVGRenderState*> *states;
@property (readonly, nonatomic) NSSize size;
@property (readonly, nonatomic) double scale;
@property (readonly, nonatomic) CGLayerRef renderLayer;

- (void)pushRenderState;
- (void)popRenderState;

- (void)prepareRender:(double)a_scale;
- (void)prepareRenderFromRenderContext:(SVGRenderContext *)prevContext;
- (void)finishRender;

- (void)setStrokeColor:(const svg_color_t *)c alpha:(CGFloat)alph;
- (void)setFillColor:(const svg_color_t *)c alpha:(CGFloat)alph;

- (double)lengthToPoints:(const svg_length_t *)l;
+ (double)lengthToPoints:(const svg_length_t *)l;

- (void)arcToRx:(double)rx ry:(double) ry
	   rotation:(double)x_axis_rotation
   largeArcFlag:(BOOL)large_arc_flag
	  sweepFlag:(BOOL)sweep_flag
			  x:(double)x y:(double)y;

- (svg_status_t)beginGroup: (double)opacity;
- (svg_status_t)endGroup: (double)opacity;

- (svg_status_t)setViewportDimensionWidth: (svg_length_t *)width height:(svg_length_t *)height;

- (svg_status_t)applyViewbox: (svg_view_box_t)viewbox withWidth: (svg_length_t *)width height: (svg_length_t *)height;


- (svg_status_t)renderRectWithX: (svg_length_t *)x y: (svg_length_t *)y
						  width: (svg_length_t *)width height: (svg_length_t *)height
						  rx: (svg_length_t *)rx ry: (svg_length_t *)ry;

- (svg_status_t)renderPath;
- (svg_status_t)renderText:(const char *)utf8 atX:(CGFloat)xPos y:(CGFloat)yPos;
- (svg_status_t)renderEllipseWithCx: (svg_length_t *)cx cy:(svg_length_t *)cy rx:(svg_length_t *)rx ry:(svg_length_t *)ry;


@end
