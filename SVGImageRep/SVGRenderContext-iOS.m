static CGColorRef CreateColorRefFromSVGColor(svg_color_t *c, CGFloat alpha)
{
	UIColor *tempColor = [UIColor colorWithRed:svg_color_get_red(c)/255.0 green:svg_color_get_green(c)/255.0 blue:svg_color_get_blue(c)/255.0 alpha:alpha];
	return CGColorRetain([tempColor CGColor]); //Need this to make it compatible with the Mac version, which returns a created CGColor
}

static CGColorSpaceRef GetGenericRGBColorSpace()
{
	static CGColorSpaceRef theSpace = NULL;
	if (theSpace == NULL) {
		theSpace = CGColorSpaceCreateDeviceRGB();
	}
	return theSpace;
}

- (void)prepareRender:(double)a_scale
{
	[self prepareRenderWithScale:a_scale renderContext:UIGraphicsGetCurrentContext()];
}

- (svg_status_t)renderText:(const char *)utf8 atX:(CGFloat)xPos y:(CGFloat)yPos
{
	CGContextRef tempCtx = CGLayerGetContext(renderLayer);
	CTFontRef f = nil, tmpfont = nil;
	//NSFontManager *fm = [NSFontManager sharedFontManager];
	//int w = ceil(current.fontWeight / 80.0);
	NSInteger i;

	svg_paint_t tempFill = self.current.fillPaint, tempStroke = self.current.strokePaint;

	if (utf8 == NULL)
	return SVG_STATUS_SUCCESS;

	NSString *utfString = [NSString stringWithUTF8String:utf8];

	{
		NSArray *families;
		NSString *family;
		
		families = [[self.current fontFamily] componentsSeparatedByString: @","];
		
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
			
			f = CTFontCreateWithName((CFStringRef)family, self.current.fontSize, NULL);
			if (f)
				break;
		}
		
		if (!f)
			f = CTFontCreateWithName(CFSTR("Helvetica"), self.current.fontSize, NULL);
	}

	{
		CFMutableDictionaryRef fontTraits = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFMutableDictionaryRef desAttribs = CFDictionaryCreateMutable(kCFAllocatorDefault, 3, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

		int fontTrait = 0;
		if (self.current.fontStyle > SVG_FONT_STYLE_NORMAL) {
			fontTrait |= kCTFontItalicTrait;
		}
		if (self.current.fontWeight >= 700) {
			fontTrait |= kCTFontBoldTrait;
		}
		CFNumberRef symTrait = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fontTrait); 
		CFDictionaryAddValue(fontTraits, kCTFontSymbolicTrait, symTrait);
		CFRelease(symTrait);
		CFDictionaryAddValue(desAttribs, kCTFontTraitsAttribute, fontTraits);
		CTFontDescriptorRef tempDes = CTFontCopyFontDescriptor(f);
		CFDictionaryRef tempDesDict = CTFontDescriptorCopyAttributes(tempDes);
		CFRelease(tempDes);
		CFStringRef fontFam = CFDictionaryGetValue(tempDesDict, kCTFontFamilyNameAttribute);
		CFDictionaryAddValue(desAttribs, kCTFontFamilyNameAttribute, fontFam);
		CFRelease(tempDesDict);

		CTFontDescriptorRef theDescriptor = CTFontDescriptorCreateWithAttributes(desAttribs);
		tmpfont = CTFontCreateWithFontDescriptor(theDescriptor, self.current.fontSize, NULL);
		CFRelease(fontTraits);
		CFRelease(theDescriptor);
		CFRelease(desAttribs);
	}

	//Should we set the text CTM here?
	CGContextScaleCTM(tempCtx, 1, -1);
	CGContextSetTextMatrix(tempCtx, CGAffineTransformIdentity);

	CGContextSetTextPosition(tempCtx, xPos, yPos);
	char psFontChar[512];
	{
		CTFontDescriptorRef tempDes = CTFontCopyFontDescriptor(f);
		CFDictionaryRef tempDesDict = CTFontDescriptorCopyAttributes(tempDes);
		CFRelease(tempDes);
		CFStringRef psFontName = CFDictionaryGetValue(tempDesDict, kCTFontNameAttribute);
		CFStringGetCString(psFontName, psFontChar, 511, kCFStringEncodingUTF8);
		CFRelease(tempDesDict);
	}
	CGContextSelectFont(tempCtx, psFontChar, self.current.fontSize, kCGEncodingFontSpecific);
	NSUInteger str8len = [utfString length];
	unichar *chars = malloc(sizeof(unichar) * str8len);
	CGGlyph *glyphChars = malloc(sizeof(CGGlyph) * str8len);
	[utfString getCharacters:chars range:NSMakeRange(0, str8len)];
	CTFontGetGlyphsForCharacters(tmpfont, chars, glyphChars, str8len);

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
	CFRelease(f);
	CFRelease(tmpfont);

	//Again, set the text CTM?
	CGContextScaleCTM(tempCtx, 1, -1);

	return SVG_STATUS_SUCCESS;
}
