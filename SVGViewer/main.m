/*
copyright 2002, 2003, 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSOpenPanel.h>

#include "Document.h"


@interface NSMenu (im_lazy)
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s;
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s  action: (SEL)sel;
@end
@implementation NSMenu (im_lazy)
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s
{
	return [self addItemWithTitle: s  action: NULL  keyEquivalent: nil];
}
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s  action: (SEL)sel
{
	return [self addItemWithTitle: s  action: sel  keyEquivalent: nil];
}
@end


@interface SVGViewer : NSObject
{
  NSMenu *_recentMenu;
}

@end


@implementation SVGViewer

-(void) dealloc
{
  [_recentMenu release];
  [super dealloc];
}

-(void) applicationWillFinishLaunching: (NSNotification *)n
{
	NSMenu *menu,*m;
        NSArray *recentDocuments;
        int i;

	menu=[[NSMenu alloc] init];

	/* 'Info' menu */
	m=[[NSMenu alloc] init];
	[m addItemWithTitle: @"Info..."
		action: @selector(orderFrontStandardInfoPanel:)];
	[m addItemWithTitle: @"Preferences..."
		action: @selector(openPreferences:)];
	[menu setSubmenu: m forItem: [menu addItemWithTitle: @"Info"]];
	[m release];

	/* 'SVG' menu */
	m=[[NSMenu alloc] init];
	[m addItemWithTitle: @"Open..."
		action: @selector(openDocument:)
		keyEquivalent: @"o"];
	
	_recentMenu=[[NSMenu alloc] init];
        recentDocuments = [[NSUserDefaults standardUserDefaults] arrayForKey:@"RecentDocuments"];
	for (i=0;i < [recentDocuments count]; i++)
	   {
	     id mi;
	     NSString *docPath = [recentDocuments objectAtIndex:i];
	     mi = [_recentMenu addItemWithTitle: [docPath lastPathComponent]
	                  action: @selector(openDocument:)];
	     [mi setRepresentedObject: docPath];
	   }
	[m setSubmenu: _recentMenu forItem: [m addItemWithTitle: @"Recent"]]; 
	[m addItemWithTitle: @"Reload"
		action: @selector(reload:)];
	
	[menu setSubmenu: m forItem: [menu addItemWithTitle: @"SVG"]];
	[m release];

	/* 'Scale' menu */
	m=[[NSMenu alloc] init];
	[m addItemWithTitle: @"0.1"
		action: @selector(scale_0_1:)];
	[m addItemWithTitle: @"0.25"
		action: @selector(scale_0_25:)];
	[m addItemWithTitle: @"0.5"
		action: @selector(scale_0_5:)];
	[m addItemWithTitle: @"0.75"
		action: @selector(scale_0_75:)];
	[m addItemWithTitle: @"1.0"
		action: @selector(scale_1_0:)];
	[m addItemWithTitle: @"1.5"
		action: @selector(scale_1_5:)];
	[m addItemWithTitle: @"2.0"
		action: @selector(scale_2_0:)];
	[m addItemWithTitle: @"3.0"
		action: @selector(scale_3_0:)];
	[m addItemWithTitle: @"4.0"
		action: @selector(scale_4_0:)];
	[m addItemWithTitle: @"5.0"
		action: @selector(scale_5_0:)];
	[menu setSubmenu: m forItem: [menu addItemWithTitle: @"Scale"]];
	[m release];

	/* 'Windows' menu */
	m=[[NSMenu alloc] init];
	[m addItemWithTitle: @"Close"
		action: @selector(performClose:)
		keyEquivalent: @"w"];
	[menu setSubmenu: m forItem: [menu addItemWithTitle: @"Windows"]];
	[NSApp setWindowsMenu: m];
	[m release];

	m=[[NSMenu alloc] init];
	[menu setSubmenu: m forItem: [menu addItemWithTitle: @"Services"]];
	[NSApp setServicesMenu: m];
	[m release];

	[menu addItemWithTitle: @"Hide"
		action: @selector(hide:)
		keyEquivalent: @"h"];

	[menu addItemWithTitle: @"Quit"
		action: @selector(terminate:)
		keyEquivalent: @"q"];

	[NSApp setMainMenu: menu];
	[menu release];
}


-(void) applicationDidFinishLaunching: (NSNotification *)n
{
}


/*
Action for opening a document. checks wether it's from the recent documents menu
if not asks the user for a file name and then
tells Document to open it. adds it to the defaults and the recent documents menu.
*/
-(void) openDocument: (id)sender
{
	NSOpenPanel *op;
	int i;
	NSArray *filenames;
	if ([sender representedObject])
	  {
            [Document openFile: [sender representedObject]];
	  }
	else
	  {
	    op=[NSOpenPanel openPanel];
	    [op setTitle: @"Open svg file"];
	    [op setAllowsMultipleSelection: YES];
	    [op setCanChooseDirectories: NO];
	    [op setCanChooseFiles: YES];

	    if ([op runModal]!=NSOKButton)
		return;
            filenames = [op filenames];
	    for (i=0;i < [filenames count]; i++)
	       {
	         NSMenuItem *mi;
	         NSArray *recentDocs;
		 NSString *filepath = [filenames objectAtIndex:i];
	         [Document openFile: filepath];
/*                 mi = [[NSMenuItem alloc] initWithTitle: [filepath lastPathComponent]];
		 [mi setAction: @selector(openDocument:)];
		 [mi setRepresentedObject: filepath]; 
		 [_recentMenu insertItem: mi
		                 atIndex: 0];
		 [mi release];
		 recentDocs = [[NSUserDefaults standardUserDefaults] 
		 			arrayForKey:@"RecentDocuments"];
		 if (!recentDocs) 
		   recentDocs = [NSMutableArray array];
		 else
		   recentDocs = [NSMutableArray arrayWithArray:recentDocs];
		 
		 [(NSMutableArray*)recentDocs insertObject: filepath
		 				   atIndex: 0];
		 [[NSUserDefaults standardUserDefaults] 
		 	setObject: recentDocs
			   forKey: @"RecentDocuments"];*/
	       }
	  }
}


@end


int main(int argc,const char **argv)
{
	NSAutoreleasePool *arp = [NSAutoreleasePool new];

	[NSApplication sharedApplication];
	[NSApp setDelegate: [[SVGViewer alloc] init]];
	[NSApp run];
	//NSApplicationMain(argc, (const char **)argv);

	[arp drain];
	return 0;
}

