//
//  SVGImageView.h
//  SVGImageRep
//
//  Created by Charles Betts on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVGImageView : UIView {
	void *svgPrivate;
}

- (void)setSVGFileName:(NSString *)path;
- (void)setSVGFileURL:(NSURL *)url;

@end
