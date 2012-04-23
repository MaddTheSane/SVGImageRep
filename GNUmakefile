# copyright 2003 Alexander Malmberg <alexander@malmberg.org>
#
# Standard GNUstep application makefile.

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME =	SVGViewer

ADDITIONAL_OBJCFLAGS += -Wall `pkg-config --cflags libsvg` -ISVGImageRep

APP_NAME = SVGViewer

SVGViewer_OBJC_FILES = \
	SVGViewer/main.m \
	SVGViewer/SVGDocument.m \
	SVGImageRep/SVGRenderState.m \
	SVGImageRep/SVGRenderContext.m

SVGViewer_HAS_RESOURCE_BUNDLE = yes

SVGViewer_RESOURCE_FILES = \
	SVGViewer/SVGDocument.xib \
	SVGViewer/SVGViewer.xib \
	SVGViewer/en.lproj
	
SVGViewer_LANGUAGES = \
	SVGViewer/en

SVGViewer_LDFLAGS += `pkg-config --libs libsvg` -lopal -lgnustep-corebase

BUNDLE_NAME = SVGImageRep

SVGImageRep_OBJC_FILES = \
	SVGImageRep/SVGImageRep.m \
	SVGImageRep/SVGRenderState.m \
	SVGImageRep/SVGRenderContext.m
	
SVGImageRep_RESOURCE_FILES = \
	SVGImageRep/en.lproj
	
SVGImageRep_LANGUAGES = \
	SVGImageRep/en

SVGImageRep_LDFLAGS += `pkg-config --libs libsvg` -lopal -lgnustep-corebase
SVGImageRep_PRINCIPAL_CLASS = SVGImageRep


include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/bundle.make

