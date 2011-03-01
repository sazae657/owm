#import <locale.h>
#import "Xlocal.h"
#import "OwmCore.h"

static Bool isFatal = False;
id globalInstance = NULL;

int
xerrorstart(Display *dpy, XErrorEvent *ee) {
	fputs("BadWindow \n", stderr);
	isFatal = True;
	return -1;
}

int
xerror(Display *disp, XErrorEvent *e) {
	return [globalInstance procotlError :disp :e];
}


int
main(argc, argv)
	int argc;
	char **argv;
{
	Display* disp;
	globalInstance = NULL;
	char c;

	if (!setlocale(LC_CTYPE, "") || !XSupportsLocale()) {
		fputs("warning: no locale support\n", stderr);
	}

	if (NULL == (disp = XOpenDisplay(NULL))) {
		fputs("cannot open display\n", stderr);
		return -1;
	}
	
	isFatal = False;
	XSetErrorHandler(xerrorstart);
	XSelectInput(disp, DefaultRootWindow(disp), SubstructureRedirectMask);
	XSync(disp, False);
	if (isFatal) {
		fputs("another window manager is already running\n", stderr);
	}
	XSetErrorHandler(NULL);
	XSync(disp, False);
	if(!isFatal) {
		globalInstance = [[OwmCore alloc] init:disp];
		[globalInstance scan];
		[globalInstance run];
		c = getchar();
		[globalInstance destroyWm];
	}
	XCloseDisplay(disp);
	return 0;
}


