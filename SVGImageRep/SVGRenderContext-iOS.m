

- (void)prepareRender:(double)a_scale
{
states = [[NSMutableArray alloc] init];
current = nil;
hasSize = NO;
scale = a_scale;
size = NSMakeSize(500 * scale, 500 * scale);
unsizedRenderLayer = CGLayerCreateWithContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], NSSizeToCGSize(size), NULL);
}

- (svg_status_t)renderText:(const char *)utf8 atX:(CGFloat)xPos y:(CGFloat)yPos
{

}

static svg_status_t r_render_image(void *closure, unsigned char *data, unsigned int data_width, unsigned int data_height, svg_length_t *x, svg_length_t *y, svg_length_t *width, svg_length_t *height)
{ 
	
}
