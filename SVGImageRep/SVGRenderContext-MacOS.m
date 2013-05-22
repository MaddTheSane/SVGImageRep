static inline CGColorRef CreateColorRefFromSVGColor(svg_color_t *c, CGFloat alpha)
{
	return CGColorCreateGenericRGB(svg_color_get_red(c)/255.0, svg_color_get_green(c)/255.0, svg_color_get_blue(c)/255.0, alpha);
}

static CGColorSpaceRef GetGenericRGBColorSpace()
{
	static CGColorSpaceRef theSpace = NULL;
	if (theSpace == NULL) {
		theSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	}
	return theSpace;
}

- (void)prepareRender:(double)a_scale
{
	[self prepareRenderWithScale:a_scale renderContext:(CGContextRef)[[NSGraphicsContext currentContext] graphicsPort]];
}

- (svg_status_t)renderText:(const char *)utf8 atX:(CGFloat)xPos y:(CGFloat)yPos
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	NSFont *f = nil;
	NSFontManager *fm = [NSFontManager sharedFontManager];
	NSInteger w = ceil(self.current.fontWeight / 80.0);
	NSInteger i;

	svg_paint_t tempFill = self.current.fillPaint, tempStroke = self.current.strokePaint;

	if (utf8 == NULL)
	return SVG_STATUS_SUCCESS;

	NSString *utfString = @(utf8);

	{
		NSFontTraitMask fontTrait = 0;
		if (self.current.fontStyle > SVG_FONT_STYLE_NORMAL) {
			fontTrait |= NSItalicFontMask;
		}
		if (self.current.fontWeight >= 700) {
			fontTrait |= NSBoldFontMask;
		}
		
		NSArray *families;
		NSString *family;
		
		families = [self.current.fontFamily componentsSeparatedByString: @","];
		
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
			
			f = [fm fontWithFamily:family traits:fontTrait weight:w size:self.current.fontSize];
			if (f)
				break;
		}
		
		if (!f)
			f = [fm fontWithFamily:@"Helvetica" traits:fontTrait weight:w size:self.current.fontSize];
	}

	//Should we set the text CTM here?
	CGContextScaleCTM(tempCtx, 1, -1);
	CGContextSetTextMatrix(tempCtx, CGAffineTransformIdentity);

#if 0

	NSAttributedString *textWFont = nil;
	{
		NSMutableDictionary *fontAttribs = [NSMutableDictionary dictionaryWithCapacity:2];
		
		[fontAttribs setValue:f forKey:NSFontAttributeName];
		NSColor *foreColor;
		if (tempFill.type == SVG_PAINT_TYPE_COLOR) {
			svg_color_t *tempsvgcolor = &tempFill.p.color;
			[self setFillColor:tempsvgcolor alpha:current.fillOpacity];
			foreColor = [NSColor colorWithDeviceRed:svg_color_get_red(tempsvgcolor)/255.0 green:svg_color_get_green(tempsvgcolor)/255.0 blue:svg_color_get_blue(tempsvgcolor)/255.0 alpha:current.fillOpacity];
		} else {
			foreColor = [NSColor clearColor];
		}
		[fontAttribs setValue:foreColor forKey:NSForegroundColorAttributeName];
		
		if (tempStroke.type == SVG_PAINT_TYPE_COLOR) {
			svg_color_t *tempsvgcolor = &tempStroke.p.color;
			[self setStrokeColor:tempsvgcolor alpha:current.strokeOpacity];
			[fontAttribs setValue:[NSColor colorWithDeviceRed:svg_color_get_red(tempsvgcolor)/255.0 green:svg_color_get_green(tempsvgcolor)/255.0 blue:svg_color_get_blue(tempsvgcolor)/255.0 alpha:current.strokeOpacity] forKey:NSStrokeColorAttributeName];
			[fontAttribs setValue:[NSNumber numberWithInteger:w] forKey:NSStrokeWidthAttributeName];
		}
		
		textWFont = [[NSAttributedString alloc] initWithString:utfString attributes:fontAttribs];
	}

	CFRange fitRange;
	CTFrameRef tempFrame;
	{
		CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(BRIDGE(CFAttributedStringRef, textWFont));
		CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [textWFont length]), NULL, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX), &fitRange);
		CGMutablePathRef pathRef;
		pathRef = CGPathCreateMutable();
		CGPathMoveToPoint(pathRef, NULL, xPos, yPos);
		CGPathAddLineToPoint(pathRef, NULL, xPos + frameSize.width, yPos);
		CGPathAddLineToPoint(pathRef, NULL, xPos + frameSize.width, yPos - frameSize.height);
		CGPathAddLineToPoint(pathRef, NULL, xPos, yPos - frameSize.height);
		CGPathCloseSubpath(pathRef);
		tempFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [textWFont length]), pathRef, NULL);
		CGPathRelease(pathRef);
		CFRelease(framesetter);
	}
	CTFrameDraw(tempFrame, tempCtx);
	CFRelease(tempFrame);
	RELEASEOBJ(textWFont);

#else

	CGContextSetTextPosition(tempCtx, xPos, yPos);
	CGContextSelectFont(tempCtx, [[[f fontDescriptor] postscriptName] UTF8String], self.current.fontSize, kCGEncodingFontSpecific);
	NSUInteger str8len = [utfString length];
	unichar *chars = malloc(sizeof(unichar) * str8len);
	CGGlyph *glyphChars = malloc(sizeof(CGGlyph) * str8len);
	[utfString getCharacters:chars range:NSMakeRange(0, str8len)];
	CTFontGetGlyphsForCharacters(BRIDGE(CTFontRef, f), chars, glyphChars, str8len);

	switch (tempFill.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			CGContextSetTextDrawingMode(tempCtx, kCGTextFillClip);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			
			//CGContextClip(tempCtx);
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
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setFillColor:&tempFill.p.color alpha:self.current.fillOpacity];
			CGContextSetTextDrawingMode(tempCtx, kCGTextFill);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			break;
			
		case SVG_PAINT_TYPE_NONE:
			break;
	}

	switch (tempStroke.type)
	{
		case SVG_PAINT_TYPE_GRADIENT:
		{
			CGContextSaveGState(tempCtx);
			CGContextSetTextDrawingMode(tempCtx, kCGTextStrokeClip);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			//CGContextClip(tempCtx);
			CGGradientRef gradient = CreateGradientRefFromSVGGradient(tempStroke.p.gradient);
			switch (tempStroke.p.gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					CGFloat x1, y1, x2, y2;
					x1 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.x1];
					y1 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.y1];
					x2 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.x2];
					y2 = [self lengthToPoints:&tempStroke.p.gradient->u.linear.y2];
					CGContextDrawLinearGradient(tempCtx, gradient, CGPointMake(x1, y1), CGPointMake(x2, y2), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
				}
					break;
					
				case SVG_GRADIENT_RADIAL:
				{
					CGFloat cx, cy, r, fx, fy;
					cx = [self lengthToPoints:&tempStroke.p.gradient->u.radial.cx];
					cy = [self lengthToPoints:&tempStroke.p.gradient->u.radial.cy];
					r = [self lengthToPoints:&tempStroke.p.gradient->u.radial.r];
					fx = [self lengthToPoints:&tempStroke.p.gradient->u.radial.fx];
					fy = [self lengthToPoints:&tempStroke.p.gradient->u.radial.fy];
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
			break;
			
		case SVG_PAINT_TYPE_COLOR:
			[self setStrokeColor:&tempStroke.p.color alpha:self.current.strokeOpacity];
			CGContextSetTextDrawingMode(tempCtx, kCGTextStroke);
			CGContextShowGlyphs(tempCtx, glyphChars, str8len);
			break;
			
		case SVG_PAINT_TYPE_NONE:
			break;
	}
	free(chars);
	free(glyphChars);
#endif

	//Again, set the text CTM?
	CGContextScaleCTM(tempCtx, 1, -1);

	return SVG_STATUS_SUCCESS;
}
