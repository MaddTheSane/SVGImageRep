//
//  SVGTViewController.m
//  SVGTester
//
//  Created by Charles Betts on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGTViewController.h"
#import "SVGImageRepiOS.h"
@interface SVGTViewController ()

@end

@implementation SVGTViewController
@synthesize testView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	NSURL *imageLoc = [[NSBundle mainBundle] URLForResource:@"admon-caution" withExtension:@"svg"];
	// Do any additional setup after loading the view, typically from a nib.
	NSData *imgData = [NSData dataWithContentsOfURL:imageLoc];
	CGImageRef tempImage = CreateSVGImageFromDataWithScale(imgData, 3.0);
	self.testView.image = [UIImage imageWithCGImage:tempImage];
	CGImageRelease(tempImage);
}

- (void)viewDidUnload
{
    [self setTestView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

- (void)dealloc {
    [testView release];
    [super dealloc];
}
@end
