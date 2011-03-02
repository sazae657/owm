#import "Xlocal.h"
#import <objc/Object.h>
#import "OwmWindow.h"

enum { CurNormal, CurResize, CurMove, CurLast };        /* cursor */
enum { ColBorder, ColFG, ColBG, ColLast };              /* color */
enum { WMProtocols, WMDelete, WMState, WMLast };
enum { ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle,
	       ClkClientWin, ClkRootWin, ClkLast };
enum { NetSupported, NetWMName, NetWMState,
	       NetWMFullscreen, NetLast };
typedef struct {
	int x, y, w, h;
	unsigned long norm[ColLast];
	unsigned long sel[ColLast];
	Drawable drawable;
	GC gc;
	struct {
		int ascent;
		int descent;
		int height;
		XFontSet set;
		XFontStruct *xfont;
	} font;
} DC; /* draw context */

@interface OwmCore : Object
{
	Display*	_display;
	int			_screen;
	Window		_root;
	DC			_dc;
	int			_sw;
	int			_sh;
	int			_bh;
	Atom		_wmatom[WMLast];
	Atom		_netatom[NetLast];
	Monitor*	_mons;
	Monitor*	_selfmon;
}

-init :(Display*) disp;
-createWm;
-destroyWm;
-(Bool)updateGeom;
-configure:(Client*)c;
-attach:(Client*)c;
-attachStack:(Client*)c;
-detach:(Client*)c;
-detachStack:(Client*)c;

-onMapRequest:(XEvent*)e;

-drawsquare :(Bool)filled :(Bool)empty :(Bool) invert :(unsigned long) col;
-drawbar :(Monitor*)m;
-updateBarpos :(Monitor*)m;
-updateBorders;
-arrange :(Monitor*)m;
-arrangeMon :(Monitor*)m;
-restack :(Monitor*)m;
-showhide :(Client*)c;
-resize :(Client*)c :(int)x :(int)y :(int)w :(int)h :(Bool)interact;
-resizeclient :(Client*)c :(int)x :(int)y :(int)w :(int) h;
-(Bool)applySizeHints :(Client*) c :(int*)x :(int*)y :(int*)w :(int*)h :(Bool)interact;
-(long)getWindowLong :(Window)w;
-(Bool)getWindowText :(Window)w :(Atom)atom :(char *)text :(unsigned int) size;
-updatesizehints :(Client*)c;
-updateTitle :(Client*)c;
-focus :(Client*)c;
-unfocus :(Client*)c :(Bool)setfocus;
-scan;
-run;
-manage :(Window)w :(XWindowAttributes*)wa;
-(Monitor*)createMon;
-(Monitor*)winToMon :(Window)w;
-(Monitor*)ptrToMon :(int)x :(int)y;
-(Client*)winToClient :(Window)w;
-(Bool)getRootPointer :(int*)x :(int*)y;
-(unsigned long)createColor :(const char*)name;
-(int)procotlError :(Display*) disp :(XErrorEvent*) ev;
@end

