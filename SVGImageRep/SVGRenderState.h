//
//  SVGRenderState.h
//  SVGImageRep
//
//  Created by Charles Betts on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <CoreGraphics/CGBase.h>
#import <Foundation/NSObject.h>
#include <svg.h>

@class NSString;

@interface SVGRenderState : NSObject <NSCopying>
@property (readwrite, nonatomic) svg_paint_t fillPaint;
@property (readwrite, nonatomic) svg_paint_t strokePaint;
@property (readwrite, nonatomic) double fillOpacity;
@property (readwrite, nonatomic) double strokeOpacity;
@property (readwrite, nonatomic) svg_color_t color;
@property (readwrite, nonatomic) double opacity;
@property (readwrite, nonatomic) double strokeWidth;
@property (readwrite, nonatomic) int fillRule;
@property (readwrite, nonatomic, copy) NSString *fontFamily;
@property (readwrite, nonatomic) svg_font_style_t fontStyle;
@property (readwrite, nonatomic) double fontSize;
@property (readwrite, nonatomic) double fontWeight;
@property (readwrite, nonatomic) svg_text_anchor_t textAnchor;
@property (readwrite, nonatomic) CGFloat *dash;
@property (readwrite, nonatomic) size_t dashLength;
@property (readwrite, nonatomic) CGFloat dashOffset;

@end
