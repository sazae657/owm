#import "Xlocal.h"
#import <objc/Object.h>
#import "OwmWindow.h"
#import "OwmScreen.h"
#import "OwmUtList.h"
#import "OwmTypes.h"

@class OwmScreen;
@class OwmClient;
@class OwmUtList;

@interface OwmCore : Object
{
	Display*	_display;
	int			_screen;
	Window		_root;
	DC			_dc;
	int			_sw;
	int			_sh;
	int			_bh;
	Atom		_wmatom[Xs_ATOM_MAX];
	Atom		_netatom[Xn_NET_MAX];
	//OwmScreen	*_mons;
	OwmScreen	*_prmScr;
	OwmUtList	*_mons;
	OwmClient	*_activeClient;
}

-init :(Display*) disp;
-createWm;
-destroyWm;
-(Bool)updateGeom;
//-attach:(Client*)c;
//-attachStack:(Client*)c;
//-detach:(Client*)c;
//-detachStack:(Client*)c;
-(unsigned long) getColor :(int)index;
-(OwmUtList*)screenList;
-(OwmScreen*)firstScreen;
-(Window)rootWindow;
-(Display*)getDisplay;
-(OwmClient*)findClient :(Window)w;
-(OwmClient*)findClientByFrame :(Window)w;
-(Atom)getNetAtom:(int)name;
-onMapRequest:(XEvent*)e;
-onMouseButtonPress:(XEvent*)e;
-onMouseButtonRelease:(XEvent*)e;
-onConfigureRequest:(XEvent*)e;

//-drawsquare :(Bool)filled :(Bool)empty :(Bool) invert :(unsigned long) col;
//-drawbar :(Monitor*)m;
//-updateBarpos :(Monitor*)m;
//-updateBorders;
//-arrange :(Monitor*)m;
//-arrangeMon :(Monitor*)m;
//-restack :(Monitor*)m;
//-showhide :(Client*)c;
//-resize :(Client*)c :(int)x :(int)y :(int)w :(int)h :(Bool)interact;
//-resizeclient :(Client*)c :(int)x :(int)y :(int)w :(int) h;
//-(Bool)applySizeHints :(Client*) c :(int*)x :(int*)y :(int*)w :(int*)h :(Bool)interact;
-(long)getWindowLong :(Window)w;
-(Bool)getWindowText :(Window)w :(Atom)atom :(char *)text :(unsigned int) size;
//-updatesizehints :(Client*)c;
//-updateTitle :(Client*)c;
-focus :(OwmClient*)c;
-unfocus :(OwmClient*)c :(Bool)setfocus;
-scan;
-run;
-(Bool)getRootPointer :(int*)x :(int*)y;
-(unsigned long)createColor :(const char*)name;
-(int)procotlError :(Display*) disp :(XErrorEvent*) ev;
@end

