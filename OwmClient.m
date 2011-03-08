#import "Xlocal.h"
#import "OwmCore.h"
#import "OwmScreen.h"
#import "OwmClient.h"
@implementation OwmClient


-(OwmScreen*)getScreen
{
	return mon;
}

-(Window)getWindow
{
	return _win;
}

-(Window)getFrame
{
	return _frame;
}

-(Bool)getWindowText :(char *)text :(unsigned int) size
{
	char **list = NULL;
	int n;
	XTextProperty name;

	if(!text || size == 0)
		return False;
	text[0] = '\0';
	if(!XGetTextProperty([_core getDisplay], _win, &name, [_core getNetAtom :Xn_NET_WM_NAME])) {
		XGetTextProperty([_core getDisplay], _win, &name, XA_WM_NAME);
	}
	if(!name.nitems)
		return False;
	if(name.encoding == XA_STRING)
		strncpy(text, (char *)name.value, size - 1);
	else {
		if(XmbTextPropertyToTextList([_core getDisplay], &name, &list, &n) >= Success && n > 0 && *list) {
			strncpy(text, *list, size - 1);
			XFreeStringList(list);
		}
	}
	text[size - 1] = '\0';
	fprintf(stderr, "GWT=%s\n", text);
	XFree(name.value);
}

-updateTitle
{
	[self getWindowText :title :sizeof(title)];
	if (title[0] == '\0') {
		strcpy(title, "Untitled");
	}
	return self;
}

-initWithAttach :(OwmCore*)core :(Window)w :(XWindowAttributes*)wa
{
	Window trans = None;
	XWindowChanges wc;
	OwmClient *t = NULL;
	_win = w;
	_core = core;
	[self updateTitle];
	
	if(XGetTransientForHint([core getDisplay], w, &trans)) {
		t = [core findClient :trans];	
	}
	if(t) {
		mon = [t getScreen];
	}
	else {
		mon = [core firstScreen];
	}

	/* geometry */
	_wndRect.x = _oldRect.x = wa->x; //+ c->mon->wx;
	_wndRect.y = _oldRect.y = wa->y; //+ c->mon->wy;
	_wndRect.w = _oldRect.w = wa->width;
	_wndRect.h = _oldRect.h = wa->height;
	
	fprintf(stderr, "geom: x=%d y=%d w=%d h=%d\n", _wndRect.x, _wndRect.y, _wndRect.w, _wndRect.h);
	if (1 == _wndRect.w) _wndRect.w += 320;
	if (1 == _wndRect.h) _wndRect.h += 240;
	
	bw = 9;
#if 0
	if (c->w == c->mon->mw && c->h == c->mon->mh) {
		c->isfloating = 1;
		c->x = c->mon->mx;
		c->y = c->mon->my;
		c->bw = 0;
	}
	else {
		if(c->x + WIDTH(c) > c->mon->mx + c->mon->mw)
			c->x = c->mon->mx + c->mon->mw - WIDTH(c);
		if(c->y + HEIGHT(c) > c->mon->my + c->mon->mh)
			c->y = c->mon->my + c->mon->mh - HEIGHT(c);
		c->x = MAX(c->x, c->mon->mx);
		c->y = MAX(c->y, ((c->mon->by == 0) && (c->x + (c->w / 2) >= c->mon->wx)
				&& (c->x + (c->w / 2) < c->mon->wx + c->mon->ww)) ? _bh : c->mon->my);
		c->bw = 8;
	}
#endif
	wc.border_width = bw;
	//XConfigureWindow(_display, w, CWBorderWidth, &wc);
	//XSetWindowBorder(_display, w, _dc.norm[ColBorder]);
	[self configure];
	//XSelectInput([_core getDisplay], 
	//		w, 
	//		EnterWindowMask|FocusChangeMask|PropertyChangeMask|StructureNotifyMask);
	if(!isfloating)
		isfloating = oldstate = trans != None || isfixed;
	if(isfloating)
		XRaiseWindow([_core getDisplay], _win);
	//[[self attach :self] attachStack :self];
	fprintf(stderr, "geom(recomp): x=%d y=%d w=%d h=%d\n", 
			_wndRect.x, _wndRect.y, _wndRect.w, _wndRect.h);
	XMoveResizeWindow([core getDisplay], _win, 
			_wndRect.x, _wndRect.y, _wndRect.w, _wndRect.h); 
	[self createWmBorder];
	//XMapWindow([core getDisplay], _win);
	//[self arrange :c->mon];
	return self;
}

-createWmBorder
{
	XSetWindowAttributes wa;
	_frame = XCreateSimpleWindow(
			[_core getDisplay], [_core rootWindow],
			_wndRect.x,
			_wndRect.y - 20,
			_wndRect.w ,
			_wndRect.h + 20 ,
			10, [_core getColor :ColFG], [_core getColor :ColBG]);
	wa.cursor = XCreateFontCursor([_core getDisplay], XC_left_ptr);
	wa.event_mask = SubstructureRedirectMask 
					| SubstructureNotifyMask | ColormapChangeMask
					| ButtonPressMask | ButtonReleaseMask | PropertyChangeMask;
	XChangeWindowAttributes([_core getDisplay], _frame, CWEventMask|CWCursor, &wa);
	XSelectInput([_core getDisplay], _frame, wa.event_mask);
	
	XSetWindowBorderWidth([_core getDisplay], _win, 0);
	XReparentWindow([_core getDisplay], _win, _frame, 19, 19);
	XMapWindow([_core getDisplay], _win);
	XMapWindow([_core getDisplay], _frame);
}

-configure
{
	XConfigureEvent ce;

	ce.type = ConfigureNotify;
	ce.display = [_core getDisplay];
	ce.event = _win;
	ce.window = _win;
	ce.x = _wndRect.x;
	ce.y = _wndRect.y;
	ce.width = _wndRect.w;
	ce.height = _wndRect.h;
	ce.border_width = 16;
	ce.above = None;
	ce.override_redirect = False;
	XSendEvent([_core getDisplay], 
			_win, False, StructureNotifyMask, (XEvent *)&ce);
	return self;
}

-resize :(int)x :(int)y :(int)w :(int) h
{
	XWindowChanges wc;

	_oldRect.x = _wndRect.x; _wndRect.x = wc.x = x;
	_oldRect.y = _wndRect.y; _wndRect.y = wc.y = y;
	_oldRect.w = _wndRect.w; _wndRect.w = wc.width = w;
	_oldRect.h = _wndRect.h; _wndRect.h = wc.height = h;
	wc.border_width = 1;
	XConfigureWindow([_core getDisplay], 
			_win, CWX|CWY|CWWidth|CWHeight|CWBorderWidth, &wc);
	[self configure];
	XSync([_core getDisplay], False);
	return self;
}

-grabStart
{
	Cursor cursor = XCreateFontCursor([_core getDisplay], XC_hand1 );
	XGrabPointer([_core getDisplay], 
			_frame, 
			False, 
			ButtonPressMask|ButtonReleaseMask|ButtonMotionMask,
			GrabModeAsync,GrabModeAsync, None, cursor, CurrentTime);
}

-grabEnd
{	
	int x,y;
	XUngrabPointer([_core getDisplay], CurrentTime);
	
	[_core getRootPointer :&x :&y];
	XMoveWindow([_core getDisplay], _frame , x, y);

}

@end

