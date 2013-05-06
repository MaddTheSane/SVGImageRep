//
//  SVGRenderContext.m
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGRenderContext.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSValue.h>
#import "SVGRenderState.h"
#include <CoreText/CoreText.h>

#if !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
#import <AppKit/NSFontManager.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontDescriptor.h>
#import <AppKit/NSAttributedString.h>
#else
#import <UIKit/UIKit.h>
#endif

@interface SVGRenderContext ()

- (void)prepareRenderWithScale:(double)a_scale renderContext:(CGContextRef)thecontext;

@property (readwrite, nonatomic) int indent;

@end

@implementation SVGRenderContext

@synthesize size, states, current, scale, renderLayer;
@synthesize indent = theIndent;

static CGGradientRef CreateGradientRefFromSVGGradient(svg_gradient_t *gradient);

#if !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
#import "SVGRenderContext-MacOS.m"
#else
#import "SVGRenderContext-iOS.m"
#endif

static CGGradientRef CreateGradientRefFromSVGGradient(svg_gradient_t *gradient)
{
	int numStops = gradient->num_stops, i;
	CFMutableArrayRef colorArray = CFArrayCreateMutable(kCFAllocatorDefault, numStops, &kCFTypeArrayCallBacks);
	CGFloat *GradStops = malloc(sizeof(CGFloat) * numStops);
	for (i = 0; i < numStops; i++) {
		CGColorRef tempColor = CreateColorRefFromSVGColor(&gradient->stops[i].color, gradient->stops[i].opacity);
		CFArrayInsertValueAtIndex(colorArray, i, tempColor);
		CGColorRelease(tempColor);
		GradStops[i] = gradient->stops[i].offset;
	}
	CGGradientRef CGgradient = CGGradientCreateWithColors(GetGenericRGBColorSpace(), colorArray, GradStops);
	CFRelease(colorArray);
	free(GradStops);
	return CGgradient;
}

- (void)prepareRenderWithScale:(double)a_scale renderContext:(CGContextRef)theContext
{
	states = [[NSMutableArray alloc] init];
	current = nil;
	hasSize = NO;
	scale = a_scale;
	if (NSEqualSizes(size, NSZeroSize)) {
		size = NSMakeSize(500 * scale, 500 * scale);
	}
	theIndent = 1;
	unsizedRenderLayer = CGLayerCreateWithContext(theContext, NSSizeToCGSize(size), NULL);
}

- (void)prepareRenderFromRenderContext:(SVGRenderContext *)prevContext
{
	size = prevContext.size;
	[self prepareRenderWithScale:prevContext.scale renderContext:CGLayerGetContext(prevContext.renderLayer)];
	
	[states addObject:[prevContext.current copy]];
	current = [states objectAtIndex:[states count] - 1];
	RELEASEOBJ(current);
	hasSize = NO;
}

- (void)finishRender
{
	RELEASEOBJ(states); states = nil;
	hasSize = NO;
	CGLayerRelease(unsizedRenderLayer);
	unsizedRenderLayer = NULL;
}

- (void)dealloc
{
	CGLayerRelease(renderLayer);
	
	SUPERDEALLOC;
}

- (void)finalize
{
	CGLayerRelease(renderLayer);
	
	[super finalize];
}

+ (double)lengthToPoints:(svg_length_t *)l
{
	double points;
	switch (l->unit)
	{
		case SVG_LENGTH_UNIT_PT:
			points = l->value;
			break;
			
		case SVG_LENGTH_UNIT_PX:
			points = l->value / 1.25;
			break;
			
		case SVG_LENGTH_UNIT_CM:
			points = l->value / 2.54 * 72;
			break;
			
		case SVG_LENGTH_UNIT_MM:
			points = l->value / 25.4 * 72;
			break;
			
		case SVG_LENGTH_UNIT_IN:
			points = l->value * 72;
			break;
			
		case SVG_LENGTH_UNIT_PC:
			points = l->value / 6 * 72;
			break;
			
			//Assume a resolution of 100 when using percents
		case SVG_LENGTH_UNIT_PCT:
			if (l->orientation == SVG_LENGTH_ORIENTATION_HORIZONTAL)
				return l->value;
			else if (l->orientation == SVG_LENGTH_ORIENTATION_VERTICAL)
				return l->value;
			else
				return l->value / 100 * sqrt(100 * 100 + 100 * 100) * sqrt(2);
			
		default:
			fprintf(stderr, "SVGRenderContext: unhandled unit %i\n", l->unit);
			return l->value;
	}
	return points * 1.25;
}

- (double)lengthToPoints:(svg_length_t *)l
{
	double points;
	switch (l->unit)
	{
		case SVG_LENGTH_UNIT_PT:
			points = l->value;
			break;
			
		case SVG_LENGTH_UNIT_PX:
			points = l->value / 1.25;
			break;
			
		case SVG_LENGTH_UNIT_CM:
			points = l->value / 2.54 * 72;
			break;
			
		case SVG_LENGTH_UNIT_MM:
			points = l->value / 25.4 * 72;
			break;
			
		case SVG_LENGTH_UNIT_IN:
			points = l->value * 72;
			break;
			
		case SVG_LENGTH_UNIT_PC:
			points = l->value / 6 * 72;
			break;
			
		case SVG_LENGTH_UNIT_PCT:
			if (l->orientation == SVG_LENGTH_ORIENTATION_HORIZONTAL)
				return l->value / 100 * size.width / scale;
			else if (l->orientation == SVG_LENGTH_ORIENTATION_VERTICAL)
				return l->value / 100 * size.height / scale;
			else
				return l->value / 100 * sqrt(size.width * size.width + size.height * size.height) * sqrt(2) / scale;
			
		default:
			fprintf(stderr, "SVGRenderContext: unhandled unit %i\n", l->unit);
			return l->value;
	}
	return points * 1.25;
}

- (void)setStrokeColor:(svg_color_t *)c alpha:(CGFloat)alph
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	CGColorRef tempColor = CreateColorRefFromSVGColor(c, alph);
	CGContextSetStrokeColorWithColor(tempCtx, tempColor);
	CGColorRelease(tempColor);
}

- (void)setFillColor:(svg_color_t *)c alpha:(CGFloat)alph
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	CGColorRef tempColor = CreateColorRefFromSVGColor(c, alph);
	CGContextSetFillColorWithColor(tempCtx, tempColor);
	CGColorRelease(tempColor);
}

/*
 A few methods based on code in libxsvg:
 */

/* libxsvg - Render XVG documents using the Xr library
 *
 * Copyright © 2002 USC/Information Sciences Institute
 *
 * Permission to use, copy, modify, distribute, and sell this software
 * and its documentation for any purpose is hereby granted without
 * fee, provided that the above copyright notice appear in all copies
 * and that both that copyright notice and this permission notice
 * appear in supporting documentation, and that the name of
 * Information Sciences Institute not be used in advertising or
 * publicity pertaining to distribution of the software without
 * specific, written prior permission.  Information Sciences Institute
 * makes no representations about the suitability of this software for
 * any purpose.  It is provided "as is" without express or implied
 * warranty.
 *
 * INFORMATION SCIENCES INSTITUTE DISCLAIMS ALL WARRANTIES WITH REGARD
 * TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL INFORMATION SCIENCES
 * INSTITUTE BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
 * OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 * Author: Carl Worth <cworth@isi.edu>
 */
/* The ellipse and arc functions below are:
 
 Copyright (C) 2000 Eazel, Inc.
 
 Author: Raph Levien <raph@artofcode.com>
 
 This is adapted from svg-path in Gill.
 */
/* 4/3 * (1-cos 45°)/sin 45° = 4/3 * sqrt(2) - 1 */
#define SVG_ARC_MAGIC ((double) 0.5522847498)
- (void)_pathArcSegment:(double)xc : (double)yc
					   : (double)th0 : (double)th1
					   : (double)rx : (double)ry : (double)x_axis_rotation
{
    double sin_th, cos_th;
    double a00, a01, a10, a11;
    double x1, y1, x2, y2, x3, y3;
    double t;
    double th_half;
	
    sin_th = sin(x_axis_rotation * (M_PI / 180.0));
    cos_th = cos(x_axis_rotation * (M_PI / 180.0)); 
    /* inverse transform compared with rsvg_path_arc */
    a00 = cos_th * rx;
    a01 = -sin_th * ry;
    a10 = sin_th * rx;
    a11 = cos_th * ry;
	
    th_half = 0.5 * (th1 - th0);
    t = (8.0 / 3.0) * sin(th_half * 0.5) * sin(th_half * 0.5) / sin(th_half);
    x1 = xc + cos(th0) - t * sin(th0);
    y1 = yc + sin(th0) + t * cos(th0);
    x3 = xc + cos(th1);
    y3 = yc + sin(th1);
    x2 = x3 + t * sin(th1);
    y2 = y3 - t * cos(th1);
	
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	CGContextAddCurveToPoint(tempCtx, a00 * x1 + a01 * y1, a10 * x1 + a11 * y1, a00 * x2 + a01 * y2, a10 * x2 + a11 * y2, a00 * x3 + a01 * y3, a10 * x3 + a11 * y3);	
}

/**
 * _xsvg_path_arc_to: Add an arc to the given path
 *
 * rx: Radius in x direction (before rotation).
 * ry: Radius in y direction (before rotation).
 * x_axis_rotation: Rotation angle for axes.
 * large_arc_flag: 0 for arc length <= 180, 1 for arc >= 180.
 * sweep: 0 for "negative angle", 1 for "positive angle".
 * x: New x coordinate.
 * y: New y coordinate.
 *
 **/
- (void)arcTo:(double)rx : (double) ry
			 : (double)x_axis_rotation
			 : (int)large_arc_flag
			 : (int)sweep_flag
			 : (double)x
			 : (double)y
{
    double sin_th, cos_th;
    double a00, a01, a10, a11;
    double x0, y0, x1, y1, xc, yc;
    double d, sfactor, sfactor_sq;
    double th0, th1, th_arc;
    int i, n_segs;
    double dx, dy, dx1, dy1, Pr1, Pr2, Px, Py, check;
    double curx;
    double cury;
	
	{
		CGContextRef tempCtx = CGLayerGetContext(renderLayer);
		CGPoint tempPoint = CGContextGetPathCurrentPoint(tempCtx);
		curx = tempPoint.x;
		cury = tempPoint.y;
	}
	
    sin_th = sin(x_axis_rotation * (M_PI / 180.0));
    cos_th = cos(x_axis_rotation * (M_PI / 180.0));
	
    dx = (curx - x) / 2.0;
    dy = (cury - y) / 2.0;
    dx1 =  cos_th * dx + sin_th * dy;
    dy1 = -sin_th * dx + cos_th * dy;
    Pr1 = rx * rx;
    Pr2 = ry * ry;
    Px = dx1 * dx1;
    Py = dy1 * dy1;
    /* Spec : check if radii are large enough */
    check = Px / Pr1 + Py / Pr2;
    if(check > 1)
    {
        rx = rx * sqrt(check);
        ry = ry * sqrt(check);
    }
	
    a00 = cos_th / rx;
    a01 = sin_th / rx;
    a10 = -sin_th / ry;
    a11 = cos_th / ry;
    x0 = a00 * curx + a01 * cury;
    y0 = a10 * curx + a11 * cury;
    x1 = a00 * x + a01 * y;
    y1 = a10 * x + a11 * y;
    /* (x0, y0) is current point in transformed coordinate space.
	 (x1, y1) is new point in transformed coordinate space.
	 
	 The arc fits a unit-radius circle in this space.
	 */
    d = (x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0);
    sfactor_sq = 1.0 / d - 0.25;
    if (sfactor_sq < 0) sfactor_sq = 0;
    sfactor = sqrt(sfactor_sq);
    if (sweep_flag == large_arc_flag) sfactor = -sfactor;
    xc = 0.5 * (x0 + x1) - sfactor * (y1 - y0);
    yc = 0.5 * (y0 + y1) + sfactor * (x1 - x0);
    /* (xc, yc) is center of the circle. */
    
    th0 = atan2(y0 - yc, x0 - xc);
    th1 = atan2(y1 - yc, x1 - xc);
    
    th_arc = th1 - th0;
    if (th_arc < 0 && sweep_flag)
		th_arc += 2 * M_PI;
    else if (th_arc > 0 && !sweep_flag)
		th_arc -= 2 * M_PI;
	
    /* XXX: I still need to evaluate the math performed in this
	 function. The critical behavior desired is that the arc must be
	 approximated within an arbitrary error tolerance, (which the
	 user should be able to specify as well). I don't yet know the
	 bounds of the error from the following computation of
	 n_segs. Plus the "+ 0.001" looks just plain fishy. -cworth */
    n_segs = ceil(fabs(th_arc / (M_PI * 0.5 + 0.001)));
    
    for (i = 0; i < n_segs; i++) {
		[self _pathArcSegment: xc : yc
							 : th0 + i * th_arc / n_segs
							 : th0 + (i + 1) * th_arc / n_segs
							 : rx : ry : x_axis_rotation];
    }
}

- (svg_status_t)renderRectWithX: (svg_length_t *)x y: (svg_length_t *)y
						  width: (svg_length_t *)width height: (svg_length_t *)height
							 rx: (svg_length_t *)rx ry: (svg_length_t *)ry;
{
	double cx, cy, cw, ch;
	double crx, cry;
	
	cx = [self lengthToPoints:x];
	cy = [self lengthToPoints:y];
	cw = [self lengthToPoints:width];
	ch = [self lengthToPoints:height];
	crx = [self lengthToPoints:rx];
	cry = [self lengthToPoints:ry];
	
	if (crx > cw / 2) crx = cw / 2;
	if (cry > ch / 2) cry = ch / 2;
	
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	svg_paint_t tempFill = current.fillPaint, tempStroke = current.strokePaint;
	
	switch (tempFill.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempFill.p.gradient);
			if (rx > 0 || ry > 0)
			{
				CGContextMoveToPoint(tempCtx, cx + crx, cy);
				CGContextAddLineToPoint(tempCtx, cx + cw - crx, cy);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + cw : cy + cry];
				CGContextAddLineToPoint(tempCtx, cx + cw, cy + ch - cry);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + cw - crx : cy + ch];
				CGContextAddLineToPoint(tempCtx, cx + crx, cy + ch);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx : cy + ch - cry];
				CGContextAddLineToPoint(tempCtx, cx, cy + cry);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + crx : cy];
				CGContextClosePath(tempCtx);
				CGContextClip(tempCtx);
			}
			else
				CGContextClipToRect(tempCtx, CGRectMake(cx, cy, cw, ch));
			
			switch (tempFill.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					CGFloat x1, y1, x2, y2;
					x1 = [self lengthToPoints:&tempFill.p.gradient->u.linear.x1];
					y1 = [self lengthToPoints:&tempFill.p.gradient->u.linear.y1];
					x2 = [self lengthToPoints:&tempFill.p.gradient->u.linear.x2];
					y2 = [self lengthToPoints:&tempFill.p.gradient->u.linear.y2];
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake(x1, y1), CGPointMake(x2, y2), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
					
				case SVG_GRADIENT_RADIAL:
				{
					CGFloat cx, cy, r, fx, fy;
					cx = [self lengthToPoints:&tempFill.p.gradient->u.radial.cx];
					cy = [self lengthToPoints:&tempFill.p.gradient->u.radial.cy];
					r = [self lengthToPoints:&tempFill.p.gradient->u.radial.r];
					fx = [self lengthToPoints:&tempFill.p.gradient->u.radial.fx];
					fy = [self lengthToPoints:&tempFill.p.gradient->u.radial.fy];
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake(cx, cy), r, CGPointMake(fx, fy), r, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
			}
			CGGradientRelease(gradient);
			CGContextRestoreGState(tempCtx);
		}
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			CGContextSaveGState(tempCtx);
		{
			
			if (rx > 0 || ry > 0)
			{
				CGContextMoveToPoint(tempCtx, cx + crx, cy);
				CGContextAddLineToPoint(tempCtx, cx + cw - crx, cy);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + cw : cy + cry];
				CGContextAddLineToPoint(tempCtx, cx + cw, cy + ch - cry);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + cw - crx : cy + ch];
				CGContextAddLineToPoint(tempCtx, cx + crx, cy + ch);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx : cy + ch - cry];
				CGContextAddLineToPoint(tempCtx, cx, cy + cry);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + crx : cy];
				CGContextClosePath(tempCtx);
				CGContextClip(tempCtx);
			}
			else
				CGContextClipToRect(tempCtx, CGRectMake(cx, cy, cw, ch));

			svg_element_t *tempElement = tempFill.p.pattern_element;
			SVGRenderContext *patternRender = [[SVGRenderContext alloc] init];
			svg_pattern_t *pattern = svg_element_pattern(tempElement);
			[patternRender prepareRenderFromRenderContext:self];
			[patternRender setViewportDimensionWidth:&pattern->width height:&pattern->height];
			svg_element_render(tempElement, &cocoa_svg_engine, BRIDGE(void*,patternRender));
			[patternRender finishRender];
			CGFloat w, h, x, y;
			w = [self lengthToPoints:&pattern->width];
			h = [self lengthToPoints:&pattern->height];
			x = [self lengthToPoints:&pattern->x];
			y = [self lengthToPoints:&pattern->y];
			int xIter = 0, yIter = 0;
			CGFloat imgSizeX = size.width / scale, imgSizeY = size.height / scale;
			
			//TODO: handle transform
			//FIXME: there has to be a better way of drawing this.
			do {
				yIter++;
				xIter = 0;
				do {
					xIter++;
					CGContextDrawLayerInRect(tempCtx, CGRectMake((x * xIter), (y * yIter), w, h), patternRender.renderLayer);
				} while (imgSizeX > (x + xIter * w));
			} while (imgSizeY > (y + yIter * h));
			//CGContextDrawLayerInRect(tempCtx, CGRectMake(x, y, w, h), patternRender.renderLayer);
			RELEASEOBJ(patternRender);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor:&tempFill.p.color alpha:current.fillOpacity];
			if (rx > 0 || ry > 0)
			{
				CGContextMoveToPoint(tempCtx, cx + crx, cy);
				CGContextAddLineToPoint(tempCtx, cx + cw - crx, cy);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + cw : cy + cry];
				CGContextAddLineToPoint(tempCtx, cx + cw, cy + ch - cry);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + cw - crx : cy + ch];
				CGContextAddLineToPoint(tempCtx, cx + crx, cy + ch);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx : cy + ch - cry];
				CGContextAddLineToPoint(tempCtx, cx, cy + cry);
				[self arcTo: crx : cry : 0 : 0 : 1 : cx + crx : cy];
				CGContextClosePath(tempCtx);
				CGContextFillPath(tempCtx);
			}
			else
				CGContextFillRect(tempCtx, CGRectMake(cx, cy, cw, ch));
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	switch (tempStroke.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
#warning SVG_PAINT_TYPE_GRADIENT not handled yet!
			CGContextSaveGState(tempCtx);
		{
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempStroke.p.gradient);
			CGGradientRelease(gradient);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor:&tempStroke.p.color alpha:current.strokeOpacity];
			CGContextStrokeRect(tempCtx, CGRectMake(cx, cy, cw, ch));
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)renderEllipseWithCx:(svg_length_t *)lcx cy:(svg_length_t *)lcy rx:(svg_length_t *)lrx ry:(svg_length_t *)lry;
{
	double cx, cy, rx, ry;
	
	cx = [self lengthToPoints:lcx];
	cy = [self lengthToPoints:lcy];
	rx = [self lengthToPoints:lrx];
	ry = [self lengthToPoints:lry];
	
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	CGContextMoveToPoint(tempCtx, cx + rx, cy);
	CGContextAddCurveToPoint(tempCtx, cx + rx, cy + ry * SVG_ARC_MAGIC, cx + rx * SVG_ARC_MAGIC, cy + ry, cx, cy + ry);
	CGContextAddCurveToPoint(tempCtx, cx - rx * SVG_ARC_MAGIC, cy + ry, cx - rx, cy + ry * SVG_ARC_MAGIC, cx - rx, cy);
	CGContextAddCurveToPoint(tempCtx, cx - rx, cy - ry * SVG_ARC_MAGIC, cx - rx * SVG_ARC_MAGIC, cy - ry, cx, cy - ry);
	CGContextAddCurveToPoint(tempCtx, cx + rx * SVG_ARC_MAGIC, cy - ry, cx + rx, cy - ry * SVG_ARC_MAGIC, cx + rx, cy);
	CGContextClosePath(tempCtx);
	[self renderPath];
	
	return SVG_STATUS_SUCCESS;
}

/*
 End of methods based on libxsvg code.
 */


- (svg_status_t)beginGroup:(double)opacity
{
	CGContextRef tempCtx;
	if (theIndent == 4) {
		tempCtx= CGLayerGetContext(unsizedRenderLayer);
	} else {
		tempCtx = CGLayerGetContext(renderLayer);
	}
	 
	SVGRenderState *newCurrent = nil;
	if (current)
	{
		if (!hasSize)
		{
			fprintf(stderr, "beginGroup: with current but no size\n");
			return SVG_STATUS_INVALID_CALL;
		}
		SVGRenderState *oldCurrent = current;
		current = nil;
		newCurrent = [oldCurrent copy];
		
		CGContextSaveGState(tempCtx);
	}
	else
	{
		CGContextSaveGState(tempCtx);
		newCurrent = [[SVGRenderState alloc] init];
	}
	[states addObject:newCurrent];
	current = newCurrent;
	RELEASEOBJ(current);
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)endGroup:(double)opacity
{
	CGContextRef tempCtx;
	if (theIndent == 1) {
		tempCtx= CGLayerGetContext(unsizedRenderLayer);
	} else {
		tempCtx = CGLayerGetContext(renderLayer);
	}
	
	CGContextRestoreGState(tempCtx);
	
	[states removeObjectAtIndex:[states count] - 1];
	if ([states count])
		current = [states objectAtIndex:[states count] - 1];
	else
		current = nil;
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)setViewportDimensionWidth:(svg_length_t *)width height:(svg_length_t *)height
{
	CGFloat w, h;
	
	if (hasSize)
	{
		fprintf(stderr, "-[SVGRenderContext setViewportDimension]: Already have size, ignoring.\n");
		return SVG_STATUS_SUCCESS;
	}
	
	w = ceil([self lengthToPoints:width]) * scale;
	h = ceil([self lengthToPoints:height]) * scale;
	size = NSMakeSize(w,h);
	
	CGLayerRelease(renderLayer);
	renderLayer = CGLayerCreateWithContext(CGLayerGetContext(unsizedRenderLayer), NSSizeToCGSize(size), NULL);
	
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	CGContextTranslateCTM(tempCtx, 0, size.height);
	CGContextScaleCTM(tempCtx, scale, -scale);
	hasSize = YES;
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)applyViewbox:(svg_view_box_t)viewbox withWidth:(svg_length_t *)width height:(svg_length_t *)height
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	double w,h;
	w = [self lengthToPoints:width];
	h = [self lengthToPoints:height];
	CGContextScaleCTM(tempCtx, w / viewbox.box.width, h / viewbox.box.height);
	CGContextTranslateCTM(tempCtx, -viewbox.box.x, -viewbox.box.y);
	return SVG_STATUS_SUCCESS;
}


- (svg_status_t)renderPath
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	svg_paint_t tempFill = current.fillPaint, tempStroke = current.strokePaint;
	switch (tempFill.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			if (current.fillRule)
				CGContextEOClip(tempCtx);
			else
				CGContextClip(tempCtx);
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempFill.p.gradient);
			
			switch (tempFill.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					CGFloat x1, y1, x2, y2;
					x1 = [self lengthToPoints:&tempFill.p.gradient->u.linear.x1];
					y1 = [self lengthToPoints:&tempFill.p.gradient->u.linear.y1];
					x2 = [self lengthToPoints:&tempFill.p.gradient->u.linear.x2];
					y2 = [self lengthToPoints:&tempFill.p.gradient->u.linear.y2];
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake(x1, y1), CGPointMake(x2, y2), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
					
				case SVG_GRADIENT_RADIAL:
				{
					CGFloat cx, cy, r, fx, fy;
					cx = [self lengthToPoints:&tempFill.p.gradient->u.radial.cx];
					cy = [self lengthToPoints:&tempFill.p.gradient->u.radial.cy];
					r = [self lengthToPoints:&tempFill.p.gradient->u.radial.r];
					fx = [self lengthToPoints:&tempFill.p.gradient->u.radial.fx];
					fy = [self lengthToPoints:&tempFill.p.gradient->u.radial.fy];
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake(cx, cy), r, CGPointMake(fx, fy), r, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
			}
			CGGradientRelease(gradient);
			CGContextRestoreGState(tempCtx);
		}
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			CGContextSaveGState(tempCtx);
		{
			CGContextClip(tempCtx);
			svg_element_t *tempElement = tempFill.p.pattern_element;
			SVGRenderContext *patternRender = [[SVGRenderContext alloc] init];
			svg_pattern_t *pattern = svg_element_pattern(tempElement);
			[patternRender prepareRenderFromRenderContext:self];
			[patternRender setViewportDimensionWidth:&pattern->width height:&pattern->height];
			svg_element_render(tempElement, &cocoa_svg_engine, BRIDGE(void*, patternRender));
			[patternRender finishRender];
			CGFloat w, h, x, y;
			w = [self lengthToPoints:&pattern->width];
			h = [self lengthToPoints:&pattern->height];
			x = [self lengthToPoints:&pattern->x];
			y = [self lengthToPoints:&pattern->y];
			int xIter = 0, yIter = 0;
			CGFloat imgSizeX = size.width / scale, imgSizeY = size.height / scale;

			//TODO: handle transform
			//FIXME: there has to be a better way of drawing this.
			do {
				yIter++;
				xIter = 0;
				do {
					xIter++;
					CGContextDrawLayerInRect(tempCtx, CGRectMake((x * xIter), (y * yIter), w, h), patternRender.renderLayer);
				} while (imgSizeX > (x + xIter * w));
			} while (imgSizeY > (y + yIter * h));
			//CGContextDrawLayerInRect(tempCtx, CGRectMake(x, y, w, h), patternRender.renderLayer);
			RELEASEOBJ(patternRender);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor:&tempFill.p.color alpha:current.fillOpacity];
			if (tempStroke.type != SVG_PAINT_TYPE_NONE)
				CGContextSaveGState(tempCtx);
			if (current.fillRule)
				CGContextEOFillPath(tempCtx);
			else
				CGContextFillPath(tempCtx);
			if (tempStroke.type != SVG_PAINT_TYPE_NONE)
				CGContextRestoreGState(tempCtx);
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	switch (tempStroke.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
#warning SVG_PAINT_TYPE_GRADIENT not handled yet!
			CGContextSaveGState(tempCtx);
		{
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempStroke.p.gradient);
			CGGradientRelease(gradient);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor:&tempStroke.p.color alpha:current.strokeOpacity];
			CGContextStrokePath(tempCtx);
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	return SVG_STATUS_SUCCESS;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Size: (%fx%f) is set: %@ scale: %f States: %li Current: %@", size.width, size.height, hasSize ? @"Yes" : @"No", scale, (long)[states count], [current description]];
}

@end

static svg_status_t r_begin_group(void *closure, double opacity)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	self.indent += 3;
	
	return [self beginGroup:opacity];
}

static svg_status_t r_begin_element(void *closure)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	self.indent += 3;
	
	CGContextSaveGState(CGCtx);
	SVGRenderState *tempState = [self.current copy];
	self.current = tempState;
	[self.states addObject:self.current];
	RELEASEOBJ(tempState);
	
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_end_element(void *closure)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	self.indent -= 3;
	
	CGContextRestoreGState(CGCtx);
	[self.states removeObjectAtIndex:[self.states count] - 1];
	if ([self.states count])
		self.current = [self.states objectAtIndex:[self.states count] - 1];
	else
		self.current = nil;
	
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_end_group(void *closure, double opacity)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	self.indent -= 3;
	
	return [self endGroup:opacity];
}


static svg_status_t r_move_to(void *closure, double x, double y)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextMoveToPoint(CGCtx, x, y);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_line_to(void *closure, double x, double y)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextAddLineToPoint(CGCtx, x, y);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_curve_to(void *closure, double x1, double y1, double x2, double y2, double x3, double y3)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextAddCurveToPoint(CGCtx, x1, y1, x2, y2, x3, y3);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_quadratic_curve_to(void *closure, double x1, double y1, double x2, double y2)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
#ifndef DONTUSECGQUADCURVE
	CGContextAddQuadCurveToPoint(CGCtx, x1, y1, x2, y2);
#else
	CGPoint currPoint = CGContextGetPathCurrentPoint(CGCtx);
	CGContextAddCurveToPoint(CGCtx,
			   currPoint.x + 2.0/3.0 * (x1 - currPoint.x),
			   currPoint.y + 2.0/3.0 * (y1 - currPoint.y),
			   x2 + 2.0/3.0 * (x1 - x2),
			   y2 + 2.0/3.0 * (y1 - y2),
			   x2,y2);

#endif
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_arc_to(void *closure, double rx, double ry, double x_axis_rotation, int large_arc_flag, int sweep_flag, double x, double y)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	[self arcTo: rx
			   : ry
			   : x_axis_rotation
			   : large_arc_flag
			   : sweep_flag
			   : x
			   : y];
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_close_path(void *closure)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextClosePath(CGCtx);
	return SVG_STATUS_SUCCESS;
}


static svg_status_t r_set_color(void *closure, const svg_color_t *color)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.color = *color;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_fill_opacity(void *closure, double opacity)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.fillOpacity = opacity;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_fill_paint(void *closure, const svg_paint_t *paint)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.fillPaint = *paint;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_fill_rule(void *closure, svg_fill_rule_t fill_rule)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	if (fill_rule == SVG_FILL_RULE_NONZERO)
		self.current.fillRule = 0;
	else
		self.current.fillRule = 1;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_family(void *closure, const char *family)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	NSString *tempString = [[NSString alloc] initWithUTF8String:family];
	self.current.fontFamily = tempString;
	RELEASEOBJ(tempString);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_size(void *closure, double size)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.fontSize = size;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_style(void *closure, svg_font_style_t style)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.fontStyle = style;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_weight(void *closure, unsigned int weight)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.fontWeight = weight;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_opacity(void *closure, double opacity)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.opacity = opacity;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_dash_array(void *closure, double *dashes, int num_dashes)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	if (self.current.dash)
		free(self.current.dash);
	self.current.dash = NULL;
	self.current.dashLength = 0;

	if (dashes && num_dashes)
	{
		CGFloat *dash = malloc(sizeof(CGFloat) * num_dashes);
#if CGFLOAT_IS_DOUBLE
		memcpy(dash, dashes, sizeof(double) * num_dashes);
#else
		int i;
		for (i = 0; i < num_dashes; i++)
			dash[i] = dashes[i];
#endif
		self.current.dash = dash;
		self.current.dashLength = num_dashes;
		CGContextSetLineDash(CGCtx, self.current.dashOffset, self.current.dash, self.current.dashLength);
	}
	else
		CGContextSetLineDash(CGCtx, 0.0, NULL, 0);

	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_dash_offset(void *closure, svg_length_t *offset)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.dashOffset = [self lengthToPoints:offset];
	CGContextSetLineDash(CGCtx, self.current.dashOffset, self.current.dash, self.current.dashLength);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_line_cap(void *closure, svg_stroke_line_cap_t line_cap)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	CGLineCap i;

	switch (line_cap)
	{
		default:
		case SVG_STROKE_LINE_CAP_BUTT:
			i = kCGLineCapButt;
			break;
		case SVG_STROKE_LINE_CAP_ROUND:
			i = kCGLineCapRound;
			break;
		case SVG_STROKE_LINE_CAP_SQUARE:
			i = kCGLineCapSquare;
			break;
	}
	CGContextSetLineCap(CGCtx, i);

	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_line_join(void *closure, svg_stroke_line_join_t line_join)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	CGLineJoin i;

	switch (line_join)
	{
		case SVG_STROKE_LINE_JOIN_BEVEL:
			i = kCGLineJoinBevel;
			break;
		default:
		case SVG_STROKE_LINE_JOIN_MITER:
			i = kCGLineJoinMiter;
			break;
		case SVG_STROKE_LINE_JOIN_ROUND:
			i = kCGLineJoinRound;
			break;
	}
	CGContextSetLineJoin(CGCtx, i);

	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_miter_limit(void *closure, double miter_limit)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextSetMiterLimit(CGCtx, miter_limit);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_opacity(void *closure, double opacity)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.strokeOpacity = opacity;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_paint(void *closure, const svg_paint_t *paint)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.strokePaint = *paint;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_width(void *closure, svg_length_t *width)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.strokeWidth = [self lengthToPoints:width];
	CGContextSetLineWidth(CGCtx, self.current.strokeWidth);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_text_anchor(void *closure, svg_text_anchor_t anchor) 
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	self.current.textAnchor = anchor;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_transform(void *closure, double a, double b, double c, double d, double e, double f)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextConcatCTM(CGCtx, CGAffineTransformMake(a, b, c, d, e, f));
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_apply_viewbox(void *closure, svg_view_box_t viewbox, svg_length_t *width, svg_length_t *height)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self applyViewbox: viewbox withWidth:width height:height];
}

static svg_status_t r_set_viewport_dimension(void *closure, svg_length_t *width, svg_length_t *height)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self setViewportDimensionWidth:width height:height];
}

static svg_status_t r_render_line(void *closure, svg_length_t *x1, svg_length_t *y1, svg_length_t *x2, svg_length_t *y2)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextMoveToPoint(CGCtx, [self lengthToPoints:x1], [self lengthToPoints:y1]);
	CGContextAddLineToPoint(CGCtx, [self lengthToPoints:x2], [self lengthToPoints:y2]);
	[self renderPath];
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_render_path(void *closure)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self renderPath];
}

static svg_status_t r_render_ellipse(void *closure, svg_length_t *cx, svg_length_t *cy, svg_length_t *rx, svg_length_t *ry)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self renderEllipseWithCx:cx cy:cy rx:rx ry:ry];
}

static svg_status_t r_render_rect(void *closure, svg_length_t *x, svg_length_t *y, svg_length_t *width, svg_length_t *height, svg_length_t *rx, svg_length_t *ry)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self renderRectWithX:x y:y width:width height:height rx:rx ry:ry];
}

static svg_status_t r_render_text(void *closure, svg_length_t *x, svg_length_t *y, const char *utf8)
{
	SVGRenderContext *self = BRIDGE(SVGRenderContext *, closure);
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);

	@autoreleasepool {
		return [self renderText:utf8 atX:[self lengthToPoints:x] y:[self lengthToPoints:y]];
	}
}

const svg_render_engine_t cocoa_svg_engine =
{
	r_begin_group,
	r_begin_element,
	r_end_element,
	r_end_group,
	
	r_move_to,
	r_line_to,
	r_curve_to,
	r_quadratic_curve_to,
	r_arc_to,
	r_close_path,
	
	r_set_color,
	r_set_fill_opacity,
	r_set_fill_paint,
	r_set_fill_rule,
	r_set_font_family,
	r_set_font_size,
	r_set_font_style,
	r_set_font_weight,
	r_set_opacity,
	r_set_stroke_dash_array,
	r_set_stroke_dash_offset,
	r_set_stroke_line_cap,
	r_set_stroke_line_join,
	r_set_stroke_miter_limit,
	r_set_stroke_opacity,
	r_set_stroke_paint,
	r_set_stroke_width,
	r_set_text_anchor,
	
	r_transform,
	r_apply_viewbox,
	r_set_viewport_dimension,
	
	r_render_line,
	r_render_path,
	r_render_ellipse,
	r_render_rect,
	r_render_text,
	r_render_image
};
