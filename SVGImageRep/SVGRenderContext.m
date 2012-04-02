//
//  SVGRenderContext.m
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGRenderContext.h"
#import <AppKit/NSWindow.h>
#import <Foundation/NSArray.h>
#import "SVGRenderState.h"

@implementation SVGRenderContext

@synthesize size, states, current, scale, renderLayer;

+ (CGColorRef)colorRefFromSVGColor:(svg_color_t *)c opacity:(CGFloat)alpha
{
	return CGColorCreateGenericRGB(svg_color_get_red(c)/255.0, svg_color_get_green(c)/255.0, svg_color_get_blue(c)/255.0, alpha);
}

- (void)prepareRender:(double)a_scale
{
	states = [[NSMutableArray alloc] init];
	[current release]; current = nil;
	hasSize = NO;
	scale = a_scale;
	size = NSMakeSize(500 * scale, 500 * scale);
	unsizedRenderLayer = CGLayerCreateWithContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], size, NULL);
}

- (void)finishRender
{
	[states release]; states = nil;
	hasSize = NO;
	//TODO: release renderLayer after use.
	CGLayerRelease(unsizedRenderLayer);
	unsizedRenderLayer = NULL;
}

- (void)dealloc
{
	CGLayerRelease(renderLayer);
	[current release];
	
	[super dealloc];
}

- (void)finalize
{
	CGLayerRelease(renderLayer);
	
	[super finalize];
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
			printf("unhandled unit %i\n", l->unit);
			return l->value;
	}
	return points * 1.25;
}

- (void)setStrokeColor:(svg_color_t *)c alpha:(CGFloat)alph
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	CGColorRef tempColor = [SVGRenderContext colorRefFromSVGColor:c opacity:alph];
	CGContextSetStrokeColorWithColor(tempCtx, tempColor);
	CGColorRelease(tempColor);
	//CGContextSetRGBStrokeColor(tempCtx, svg_color_get_red(c)/255.0, svg_color_get_green(c)/255.0, svg_color_get_blue(c)/255.0, alph);
}

- (void)setFillColor:(svg_color_t *)c alpha:(CGFloat)alph
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	CGColorRef tempColor = [SVGRenderContext colorRefFromSVGColor:c opacity:alph];
	CGContextSetFillColorWithColor(tempCtx, tempColor);
	CGColorRelease(tempColor);
	//CGContextSetRGBFillColor(tempCtx, svg_color_get_red(c)/255.0, svg_color_get_green(c)/255.0, svg_color_get_blue(c)/255.0, alph);
}

+ (CGGradientRef)gradientFromSVGGradient:(svg_gradient_t *)gradient
{
	int numStops = gradient->num_stops;
	CFMutableArrayRef colorArray = CFArrayCreateMutable(kCFAllocatorDefault, numStops, &kCFTypeArrayCallBacks);
	CGFloat *GradStops = malloc(sizeof(CGFloat) * numStops);
	NSInteger i;
	for (i = 0; i < numStops; i++) {
		
		CGColorRef tempColor = [SVGRenderContext colorRefFromSVGColor:&gradient->stops[i].color opacity:gradient->stops[i].opacity];
		CFArrayInsertValueAtIndex(colorArray, i, tempColor);
		CGColorRelease(tempColor);
		GradStops[i] = gradient->stops[i].offset;
	}
	CGColorSpaceRef tempCSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGGradientRef CGgradient = CGGradientCreateWithColors(tempCSpace, colorArray, GradStops);
	CFRelease(colorArray);
	CGColorSpaceRelease(tempCSpace);
	free(GradStops);
	return CGgradient;
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


- (svg_status_t)renderRect:(svg_length_t *)x : (svg_length_t *)y
						  : (svg_length_t *)width : (svg_length_t *)height
						  : (svg_length_t *)rx : (svg_length_t *)ry
{
	double cx, cy, cw, ch;
	double crx, cry;
	
	cx = [self lengthToPoints: x];
	cy = [self lengthToPoints: y];
	cw = [self lengthToPoints: width];
	ch = [self lengthToPoints: height];
	crx = [self lengthToPoints: rx];
	cry = [self lengthToPoints: ry];
	
	if (crx > cw / 2) crx = cw / 2;
	if (cry > ch / 2) cry = ch / 2;
	
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	switch ([current fill_paint].type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			CGGradientRef gradient = [SVGRenderContext gradientFromSVGGradient:current->fill_paint.p.gradient];
			
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
			
			switch (current->fill_paint.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x1], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y1]), CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x2], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y2]), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);

					break;
					
				case SVG_GRADIENT_RADIAL:
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					break;

				default:
					break;
			}
			CGGradientRelease(gradient);
			CGContextRestoreGState(tempCtx);
		}
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor:&current->fill_paint.p.color alpha:[current fill_opacity]];
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
	
	switch ([current stroke_paint].type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
#warning SVG_PAINT_TYPE_GRADIENT not handled yet!
			CGContextSaveGState(tempCtx);
		{
			CGGradientRef gradient = [SVGRenderContext gradientFromSVGGradient:current->fill_paint.p.gradient];
			CGGradientRelease(gradient);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor:&current->stroke_paint.p.color alpha:[current stroke_opacity]];
			CGContextStrokeRect(tempCtx, CGRectMake(cx, cy, cw, ch));
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)renderEllipse:(svg_length_t *)lcx : (svg_length_t *)lcy
							 : (svg_length_t *)lrx : (svg_length_t *)lry
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
	CGContextRef tempCtx = CGLayerGetContext(unsizedRenderLayer);
	if (current)
	{
		SVGRenderState *oldCurrent = current;
		current = nil;
		current = [oldCurrent copy];
		[oldCurrent release];
		
		CGContextSaveGState(tempCtx);
	}
	else
	{
		CGContextSaveGState(tempCtx);
		current = [[SVGRenderState alloc] init];
	}
	[states addObject:current];
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)endGroup:(double)opacity
{
	CGContextRef tempCtx = CGLayerGetContext(unsizedRenderLayer);
	
	CGContextRestoreGState(tempCtx);
	
	[states removeObjectAtIndex:[states count] - 1];
	if ([states count])
		current = [states objectAtIndex:[states count] - 1];
	else
		current = nil;
	
	return SVG_STATUS_SUCCESS;
}


- (svg_status_t)setViewportDimension:(svg_length_t *)width :(svg_length_t *)height
{
	CGFloat w, h;
	
	if (hasSize)
	{
		NSLog(@"setViewportDimension: Already have size, ignoring.");
		return SVG_STATUS_SUCCESS;
	}
	
	w = ceil([self lengthToPoints: width]) * scale;
	h = ceil([self lengthToPoints: height]) * scale;
	size = NSMakeSize(w,h);
	
	CGLayerRelease(renderLayer);
	renderLayer = CGLayerCreateWithContext(CGLayerGetContext(unsizedRenderLayer), size, NULL);
	
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	CGContextTranslateCTM(tempCtx, 0, size.height);
	CGContextScaleCTM(tempCtx, scale, -scale);
	hasSize = YES;
	
	return SVG_STATUS_SUCCESS;
}

- (svg_status_t)applyViewbox: (svg_view_box_t)viewbox
							: (svg_length_t *)width : (svg_length_t *)height
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	
	CGFloat w,h;
	w = [self lengthToPoints: width];
	h = [self lengthToPoints: height];
	CGContextScaleCTM(tempCtx, w / viewbox.box.width, h / viewbox.box.height);
	CGContextTranslateCTM(tempCtx, -viewbox.box.x, -viewbox.box.y);
	return SVG_STATUS_SUCCESS;
}


- (svg_status_t)renderPath
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	switch ([current fill_paint].type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			//TODO: handle stuff like this method's case SVG_PAINT_TYPE_COLOR does.
			//I.E.: handle fill_rule.
			CGContextSaveGState(tempCtx);
			CGContextClip(tempCtx);
			CGGradientRef gradient = [SVGRenderContext gradientFromSVGGradient:current->fill_paint.p.gradient];
			
			switch (current->fill_paint.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x1], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y1]), CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x2], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y2]), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					
					break;
					
				case SVG_GRADIENT_RADIAL:
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					break;
					
				default:
					break;
			}
			CGGradientRelease(gradient);
			CGContextRestoreGState(tempCtx);
		}
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor: &current->fill_paint.p.color alpha:[current fill_opacity]];
			if (current->stroke_paint.type != SVG_PAINT_TYPE_NONE)
				CGContextSaveGState(tempCtx);
			if ([current fill_rule])
				CGContextEOFillPath(tempCtx);
			else
				CGContextFillPath(tempCtx);
			if (current->stroke_paint.type != SVG_PAINT_TYPE_NONE)
				CGContextRestoreGState(tempCtx);
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	switch ([current stroke_paint].type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
#warning SVG_PAINT_TYPE_GRADIENT not handled yet!
			CGContextSaveGState(tempCtx);
		{
			CGGradientRef gradient = [SVGRenderContext gradientFromSVGGradient:current->stroke_paint.p.gradient];
			CGGradientRelease(gradient);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor: &current->stroke_paint.p.color alpha:[current stroke_opacity]];
			CGContextStrokePath(tempCtx);
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	return SVG_STATUS_SUCCESS;
}


- (svg_status_t)renderText:(const char *)utf8
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	NSFont *f;
	NSFontManager *fm;
	NSArray *fonts, *font;
	int w = ceil([current font_weight] / 80);
	int score, best;
	NSInteger i;
	
	if (utf8 == NULL)
		return SVG_STATUS_SUCCESS;
	
	fm = [NSFontManager sharedFontManager];
	
	{
		NSArray *families;
		NSString *family;
		
		families = [[current font_family] componentsSeparatedByString: @","];
		
		fonts = nil;
		for (i = 0; i < [families count]; i++)
		{
			family = [families objectAtIndex: i];
			
			family = [family stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
			if ([family hasPrefix: @"'"])
				family = [[family substringToIndex: [family length]-1] substringFromIndex: 1];
			
			if ([family isEqual: @"serif"])
				family = @"Times";
			else if ([family isEqual: @"sans-serif"])
				family = @"Helvetica";
			else if ([family isEqual: @"monospace"])
				family = @"Courier";
			
			fonts=[fm availableMembersOfFontFamily:family];
			if (!fonts || ![fonts count])
				fonts = [fm availableMembersOfFontFamily:[family capitalizedString]];
			if (fonts && [fonts count])
				break;
		}
		
		
		if (!fonts || ![fonts count])
			fonts = [fm availableMembersOfFontFamily: @"Helvetica"];
	}
	
	f = nil;
	best = 1e6;
	//TODO: rewrite this code for better font finding.
	for (i = 0; i < [fonts count]; i++)
	{
		NSFontTraitMask traits;
		
		font=[fonts objectAtIndex: i];
		score = abs([[font objectAtIndex: 2] intValue] - w);
		
		traits = [[font objectAtIndex: 3] unsignedIntValue]&~NSBoldFontMask;
		if ([current font_style])
		{
			if (!(traits & NSItalicFontMask))
				score += 10;
			else
				traits &=~ NSItalicFontMask;
		}
		
		if (traits)
			score += 10;
		
		if (score < best)
		{
			best = score;
			f = [NSFont fontWithName: [font objectAtIndex: 0]
								size: [current font_size]];
		}
	}
	
	if (!f)
		f = [NSFont userFontOfSize: [current font_size]];
	
	NSFontDescriptor *tempDiscriptor = [NSFontDescriptor fontDescriptorWithName:[f fontName] size:[current font_size]];
	//Should we set the text CTM here?
	CGContextScaleCTM(tempCtx, 1, -1);
	CGContextSelectFont(tempCtx, [[tempDiscriptor postscriptName] UTF8String], [current font_size], kCGEncodingFontSpecific);

	switch ([current fill_paint].type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
			CGContextSaveGState(tempCtx);
			CGContextSetTextDrawingMode(tempCtx, kCGTextFillClip);
			CGContextShowText(tempCtx, utf8, strlen(utf8));
		{
			//CGContextClip(tempCtx);
			CGGradientRef gradient = [SVGRenderContext gradientFromSVGGradient:current->fill_paint.p.gradient];
			
			switch (current->fill_paint.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x1], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y1]), CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x2], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y2]), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					
					break;
					
				case SVG_GRADIENT_RADIAL:
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					break;
					
				default:
					break;
			}
			CGGradientRelease(gradient);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor: &current->fill_paint.p.color alpha:[current fill_opacity]];
			CGContextSetTextDrawingMode(tempCtx, kCGTextFill);
			CGContextShowText(tempCtx, utf8, strlen(utf8));
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	switch ([current stroke_paint].type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
			CGContextSaveGState(tempCtx);
			CGContextSetTextDrawingMode(tempCtx, kCGTextStrokeClip);
			CGContextShowText(tempCtx, utf8, strlen(utf8));
		{
			//CGContextClip(tempCtx);
			CGGradientRef gradient = [SVGRenderContext gradientFromSVGGradient:current->stroke_paint.p.gradient];
			
			switch (current->stroke_paint.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x1], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y1]), CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.linear.x2], [self lengthToPoints:&current->fill_paint.p.gradient->u.linear.y2]), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					
					break;
					
				case SVG_GRADIENT_RADIAL:
					CGContextDrawRadialGradient(tempCtx, gradient, CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.cy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], CGPointMake([self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fx], [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.fy]), [self lengthToPoints:&current->fill_paint.p.gradient->u.radial.r], kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
					break;
					
				default:
					break;
			}
			CGGradientRelease(gradient);
		}
			CGContextRestoreGState(tempCtx);
			break;
			
		case SVG_PAINT_TYPE_PATTERN:
#warning SVG_PAINT_TYPE_PATTERN not handled yet!
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor: &current->stroke_paint.p.color alpha:[current stroke_opacity]];
			CGContextSetTextDrawingMode(tempCtx, kCGTextStroke);
			CGContextShowText(tempCtx, utf8, strlen(utf8));
			break;

		case SVG_PAINT_TYPE_NONE:
			break;
	}
	
	//Again, set the text CTM?
	CGContextScaleCTM(tempCtx,1,-1);
	
	return SVG_STATUS_SUCCESS;
}

@end

static int indent = 1;

static svg_status_t r_begin_group(void *closure, double opacity)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	indent += 3;
	
	return [self beginGroup:opacity];
}

static svg_status_t r_begin_element(void *closure)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	indent += 3;
	
	CGContextSaveGState(CGCtx);
	SVGRenderState *tempState = [[self current] copy];
	self.current = tempState;
	[tempState release];
	[[self states] addObject:[self current]];
	
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_end_element(void *closure)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	indent -= 3;
	
	CGContextRestoreGState(CGCtx);
	[[self states] removeObjectAtIndex:[[self states] count] - 1];
	if ([[self states] count])
		self.current = [[self states] objectAtIndex:[[self states] count] - 1];
	else
		self.current = nil;
	
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_end_group(void *closure, double opacity)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	indent -= 3;
	
	return [self endGroup:opacity];
}


static svg_status_t r_move_to(void *closure, double x, double y)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextMoveToPoint(CGCtx, x, y);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_line_to(void *closure, double x, double y)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextAddLineToPoint(CGCtx, x, y);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_curve_to(void *closure, double x1, double y1, double x2, double y2, double x3, double y3)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextAddCurveToPoint(CGCtx, x1, y1, x2, y2, x3, y3);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_quadratic_curve_to(void *closure, double x1, double y1, double x2, double y2)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextAddQuadCurveToPoint(CGCtx, x1, y1, x2, y2);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_arc_to(void *closure, double rx, double ry, double x_axis_rotation, int large_arc_flag, int sweep_flag, double x, double y)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
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
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextClosePath(CGCtx);
	return SVG_STATUS_SUCCESS;
}


static svg_status_t r_set_color(void *closure, const svg_color_t *color)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].color = *color;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_fill_opacity(void *closure, double opacity)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].fill_opacity = opacity;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_fill_paint(void *closure, const svg_paint_t *paint)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].fill_paint = *paint;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_fill_rule(void *closure, svg_fill_rule_t fill_rule)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	if (fill_rule == SVG_FILL_RULE_NONZERO)
		[self current].fill_rule = 0;
	else
		[self current].fill_rule = 1;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_family(void *closure, const char *family)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].font_family = [NSString stringWithUTF8String:family];
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_size(void *closure, double size)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].font_size = size;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_style(void *closure, svg_font_style_t style)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].font_style = style;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_font_weight(void *closure, unsigned int weight)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].font_weight = weight;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_opacity(void *closure, double opacity)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].opacity = opacity;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_dash_array(void *closure, double *dashes, int num_dashes)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	if ([self current].dash)
		free([self current].dash);
	[self current].dash = NULL;
	[self current].num_dash = 0;

	if (dashes && num_dashes)
	{
		CGFloat *dash = malloc(sizeof(CGFloat) * num_dashes);
		size_t i;
		for (i = 0;i < num_dashes;i++)
			dash[i] = dashes[i];
		[self current].dash = dash;
		[self current].num_dash = num_dashes;
		CGContextSetLineDash(CGCtx, [[self current] dash_offset], [[self current] dash], [[self current] num_dash]);
	}
	else
		CGContextSetLineDash(CGCtx, 0.0, NULL, 0);

	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_dash_offset(void *closure, svg_length_t *offset)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].dash_offset = [self lengthToPoints: offset];
	CGContextSetLineDash(CGCtx, [[self current] dash_offset], [[self current] dash], [[self current] num_dash]);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_line_cap(void *closure, svg_stroke_line_cap_t line_cap)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
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
	SVGRenderContext *self = (SVGRenderContext *)closure;
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
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextSetMiterLimit(CGCtx, miter_limit);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_opacity(void *closure, double opacity)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].stroke_opacity = opacity;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_paint(void *closure, const svg_paint_t *paint)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].stroke_paint = *paint;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_stroke_width(void *closure, svg_length_t *width)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextSetLineWidth(CGCtx, [self lengthToPoints:width]);
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_set_text_anchor(void *closure, svg_text_anchor_t anchor) 
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	[self current].text_anchor = anchor;
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_transform(void *closure, double a, double b, double c, double d, double e, double f)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextConcatCTM(CGCtx, CGAffineTransformMake(a, b, c, d, e, f));
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_apply_viewbox(void *closure, svg_view_box_t viewbox, svg_length_t *width, svg_length_t *height)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self applyViewbox: viewbox :width :height];
}

static svg_status_t r_set_viewport_dimension(void *closure, svg_length_t *width, svg_length_t *height)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self setViewportDimension: width: height];
}

static svg_status_t r_render_line(void *closure, svg_length_t *x1, svg_length_t *y1, svg_length_t *x2, svg_length_t *y2)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextMoveToPoint(CGCtx, [self lengthToPoints:x1], [self lengthToPoints:y1]);
	CGContextAddLineToPoint(CGCtx, [self lengthToPoints:x2], [self lengthToPoints:y2]);
	[self renderPath];
	return SVG_STATUS_SUCCESS;
}

static svg_status_t r_render_path(void *closure)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self renderPath];
}

static svg_status_t r_render_ellipse(void *closure, svg_length_t *cx, svg_length_t *cy, svg_length_t *rx, svg_length_t *ry)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self renderEllipse: cx : cy : rx : ry];
}

static svg_status_t r_render_rect(void *closure, svg_length_t *x, svg_length_t *y, svg_length_t *width, svg_length_t *height, svg_length_t *rx, svg_length_t *ry)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	//CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	return [self renderRect: x:y :width:height :rx:ry];
}

static svg_status_t r_render_text(void *closure, svg_length_t *x, svg_length_t *y, const char *utf8)
{
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	
	CGContextSetTextPosition(CGCtx, [self lengthToPoints:x], [self lengthToPoints:y]);
	return [self renderText: utf8];
}

static svg_status_t r_render_image(void *closure, unsigned char *data, unsigned int data_width, unsigned int data_height, svg_length_t *x, svg_length_t *y, svg_length_t *width, svg_length_t *height)
{ 
	SVGRenderContext *self = (SVGRenderContext *)closure;
	CGContextRef CGCtx = CGLayerGetContext(self.renderLayer);
	{
		CGFloat cx, cy, cw, ch;
		cx = [self lengthToPoints:x];
		cy = [self lengthToPoints:y];
		cw = [self lengthToPoints:width];
		ch = [self lengthToPoints:height];
		NSBitmapImageRep *temprep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:data_width pixelsHigh:data_height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:data_width * 4 bitsPerPixel:32];
		CGContextDrawImage(CGCtx, CGRectMake(cx, cy, cw, ch), [temprep CGImage]);
		[temprep release];
	}

	return SVG_STATUS_SUCCESS;
}


svg_render_engine_t cocoa_svg_engine =
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
