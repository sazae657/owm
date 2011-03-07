#import "Xlocal.h"
#import "OwmScreen.h"
#import "OwmCore.h"
#import "OwmUtList.h"

static const char normbordercolor[] = "#cccccc";
static const char normbgcolor[]     = "#cccccc";
static const char normfgcolor[]     = "#000000";
static const char selbordercolor[]  = "#0066ff";
static const char selbgcolor[]      = "#0066ff";
static const char selfgcolor[]      = "#ffffff";
#define LENGTH(X)               (sizeof X / sizeof X[0])
#define INRECT(X,Y,RX,RY,RW,RH) ((X) >= (RX) && (X) < (RX) + (RW) && (Y) >= (RY) && (Y) < (RY) + (RH))
#define MAX(A, B)               ((A) > (B) ? (A) : (B))
#define MIN(A, B)               ((A) < (B) ? (A) : (B))
#define MOUSEMASK               (BUTTONMASK|PointerMotionMask)
#define WIDTH(X)                ((X)->w + 2 * (X)->bw)
#define HEIGHT(X)               ((X)->h + 2 * (X)->bw)
#define ISVISIBLE(C)            ((C->tags & C->mon->tagset[C->mon->seltags]))

static const Bool resizehints = True; 
static char* atom_names[] = {
	"_MIT_PRIORITY_COLORS",
	"WM_CHANGE_STATE",
	"WM_STATE",
	"WM_COLORMAP_WINDOWS",
	"WM_PROTOCOLS",
	"WM_TAKE_FOCUS",
	"WM_SAVE_YOURSELF",
	"WM_DELETE_WINDOW",
	"SM_CLIENT_ID",
	"WM_CLIENT_LEADER",
	"WM_WINDOW_ROLE"
};
static char* net_atom_names[] = {
	"_NET_SUPPORTED",
	"_NET_WM_NAME",
	"_NET_WM_STATE",
	"_NET_WM_STATE_FULLSCREEN"
};

@implementation OwmCore

-init :(Display*)disp 
{
	_display = disp;
	_mons = NULL;
	_prmScr = NULL;
	return [self createWm];
}

-(OwmClient*)findClient :(Window)w
{
	OwmUtList *c;
	OwmUtList *m;
	for (m = _mons; NULL != m; m = [m next]) {
		for (c = [[m get] getClients]; NULL != c; c = [c next]) {
			if([[c get] getWindow] == w) {
				return [c get];
			}
		}
	}
	return NULL;
}

-(OwmUtList*)screenList
{
	return [_mons reset];
}

-(OwmScreen*)firstScreen
{
	return [_mons first];
}

-(Window)rootWindow
{
	return _root;
}

-(Bool)updateGeom
{
	Bool dirty = False;
	if(!_mons) {
		_mons = [[OwmUtList alloc] init];
		[_mons add :[[OwmScreen alloc] initWith :self]];
	}
	OwmRect* rc = [[_mons get] getRect];
	if (rc->w != _sw || rc->h != _sh) {
		dirty = True;
		rc->w = _sw;
		rc->h = rc->h = _sh;
		//[self updateBarpos :_mons];
	}
	if(dirty) {
		//_prmScr = _mons;
		_prmScr = [[OwmScreen alloc] initWithWindow :self :_root];
	}
	fprintf(stderr, "updateGeom SW=%d SH=%d\n", _sw, _sh);
	
	return dirty;	
}

-updateBorders
{
/*	Monitor *m;
	XSetWindowAttributes wa;

	wa.override_redirect = True;
	wa.background_pixmap = ParentRelative;
	wa.event_mask = ButtonPressMask|ExposureMask;
	for (m = _mons; m; m = m->next) {
		 m->barwin = 
			XCreateWindow(_display, 
				_root, m->wx, m->by, m->ww, _bh, 0, 
				DefaultDepth(_display, _screen),
		        CopyFromParent, 
				DefaultVisual(_display, _screen),
		      	CWOverrideRedirect|CWBackPixmap|CWEventMask, &wa);
		//XDefineCursor(dpy, m->barwin, cursor[CurNormal]);
		XMapRaised(_display, m->barwin);
		fprintf(stderr, "updateBorder:wx=%d ww=%d\n", m->wx, m->ww);
	}
	*/
	return self;
}


-(long)getWindowLong :(Window)w
{
	int format;
	long result = -1;
	unsigned char *p = NULL;
	unsigned long n, extra;
	Atom real;
	
	if(XGetWindowProperty(_display, w, 
				_wmatom[Xs_WM_STATE], 0L, 2L, False, _wmatom[Xs_WM_STATE],
		 &real, &format, &n, &extra, (unsigned char **)&p) != Success) {
		return -1;
	}
	if(n != 0) {
		result = *p;
	}
	XFree(p);
	return result;
}
-(Bool)getWindowText :(Window)w :(Atom)atom :(char *)text :(unsigned int) size
{
	char **list = NULL;
	int n;
	XTextProperty name;

	if(!text || size == 0)
		return False;
	text[0] = '\0';
	XGetTextProperty(_display, w, &name, atom);
	if(!name.nitems)
		return False;
	if(name.encoding == XA_STRING)
		strncpy(text, (char *)name.value, size - 1);
	else {
		if(XmbTextPropertyToTextList(_display, &name, &list, &n) >= Success && n > 0 && *list) {
			strncpy(text, *list, size - 1);
			XFreeStringList(list);
		}
	}
	text[size - 1] = '\0';
	fprintf(stderr, "GWT=%s\n", text);
	XFree(name.value);
	return True;
}
/*
-updateTitle :(Client*)c
{
	if (![self getWindowText :c->win :_netatom[Xn_NET_WM_NAME] :c->name :sizeof(c->name)]) {
		[self getWindowText :c->win :XA_WM_NAME :c->name :sizeof(c->name)];
	}
	if (c->name[0] == '\0') {
		strcpy(c->name, "Untitled");
	}
	return self;
}
*/
-updatesizehints :(Client*)c  
{
	long msize;
	XSizeHints size;

	if(!XGetWMNormalHints(_display, c->win, &size, &msize))
		/* size is uninitialized, ensure that size.flags aren't used */
		size.flags = PSize;
	if(size.flags & PBaseSize) {
		c->basew = size.base_width;
		c->baseh = size.base_height;
	}
	else if(size.flags & PMinSize) {
		c->basew = size.min_width;
		c->baseh = size.min_height;
	}
	else
		c->basew = c->baseh = 0;
	if(size.flags & PResizeInc) {
		c->incw = size.width_inc;
		c->inch = size.height_inc;
	}
	else
		c->incw = c->inch = 0;
	if(size.flags & PMaxSize) {
		c->maxw = size.max_width;
		c->maxh = size.max_height;
	}
	else
		c->maxw = c->maxh = 0;
	if(size.flags & PMinSize) {
		c->minw = size.min_width;
		c->minh = size.min_height;
	}
	else if(size.flags & PBaseSize) {
		c->minw = size.base_width;
		c->minh = size.base_height;
	}
	else
		c->minw = c->minh = 0;
	if(size.flags & PAspect) {
		c->mina = (float)size.min_aspect.y / size.min_aspect.x;
		c->maxa = (float)size.max_aspect.x / size.max_aspect.y;
	}
	else
		c->maxa = c->mina = 0.0;
	c->isfixed = (c->maxw && c->minw && c->maxh && c->minh
	             && c->maxw == c->minw && c->maxh == c->minh);
	return self;
}



#if 0
-focus :(Client*)c
{
	if(!c || !ISVISIBLE(c)) {
		for(c = _selfmon->stack; c && !ISVISIBLE(c); c = c->snext);
	}
	if(_selfmon->sel && _selfmon->sel != c) {
		[self unfocus :_selfmon->sel :False];
	}
	if(c) {
		if(c->mon != _selfmon) {
			_selfmon = c->mon;	
		}
		//if(c->isurgent)
		//	clearurgent(c);
		[[self detachStack :c] attachStack :c];
		// grabbuttons(c, True);
		//XSetWindowBorder(_display, c->win, _dc.sel[ColBorder]);
		XSetInputFocus(_display, c->win, RevertToPointerRoot, CurrentTime);	
	}
	else {
		XSetInputFocus(_display, _root, RevertToPointerRoot, CurrentTime);
	}
	_selfmon->sel = c;
	return self;
}

-unfocus :(Client*)c :(Bool)setfocus
{
	if(!c) return self;
	//grabbuttons(c, False);
	XSetWindowBorder(_display, c->win, _dc.norm[ColBorder]);
	if (setfocus) {
		XSetInputFocus(_display, _root, RevertToPointerRoot, CurrentTime);
	}
	return self;
}

-attach:(Client*)c
{
	c->next = c->mon->clients;
	c->mon->clients = c;
	return self;
}
-attachStack:(Client*)c
{
	c->snext = c->mon->stack;
	c->mon->stack = c;
	return self;
}
-detach:(Client*)c
{
	Client **tc;
	for(tc = &c->mon->clients; *tc && *tc != c; tc = &(*tc)->next);
	*tc = c->next;
	return self;
}

-detachStack:(Client*)c
{
	Client **tc, *t;

	for(tc = &c->mon->stack; *tc && *tc != c; tc = &(*tc)->snext);
	*tc = c->snext;

	if(c == c->mon->sel) {
		for(t = c->mon->stack; t && !ISVISIBLE(t); t = t->snext);
		c->mon->sel = t;
	}
	return self;
}

-arrange :(Monitor*)m
{
	if(m) {
		[self showhide :m->stack];
	}
	else { 
		for(m = _mons; m; m = m->next) {
			[self showhide :m->stack];
		}
	}
	[self focus :NULL];
	if(m) {
		[self arrangeMon :m];
	}
	else {
		for(m = _mons; m; m = m->next) {
			[self arrangeMon :m];
		}
	}
	return self;
}

-arrangeMon :(Monitor*)m
{
	strncpy(m->ltsymbol, m->lt[m->sellt]->symbol, sizeof m->ltsymbol);
	//if(m->lt[m->sellt]->arrange)
	//		m->lt[m->sellt]->arrange(m);
	[self restack :m];
	return self;
}
-restack :(Monitor*)m
{
	Client *c;
	XEvent ev;
	XWindowChanges wc;

	if(!m->sel) {
		return self;
	}
	if(m->sel->isfloating || !m->lt[m->sellt]->arrange) {
		XRaiseWindow(_display, m->sel->win);
	}

	if(m->lt[m->sellt]->arrange) {
		wc.stack_mode = Below;
		wc.sibling = m->barwin;
		for(c = m->stack; c; c = c->snext)
			if(!c->isfloating && ISVISIBLE(c)) {
				//XConfigureWindow(_display, c->win, CWSibling|CWStackMode, &wc);
				wc.sibling = c->win;
			}
	}
	XSync(_display, False);
	while(XCheckMaskEvent(_display, EnterWindowMask, &ev));
	return self;
}

-showhide :(Client*)c
{
	if(!c) {
		return self;
	}
	if(ISVISIBLE(c)) { 
		if(!c->mon->lt[c->mon->sellt]->arrange || c->isfloating) {
			[self resize :c :c->x :c->y :c->w :c->h :False];
		}
		[self showhide :c->snext];
	}
	else {
		[self showhide :c->snext];
		//XMoveWindow(_display, c->win, c->x + 2 * _sw, c->y);
	}
	return self;
}

-(Bool)applySizeHints :(Client*) c :(int*)x :(int*)y :(int*)w :(int*)h :(Bool)interact
{
	Bool baseismin;
	Monitor *m = c->mon;

	/* set minimum possible */
	*w = MAX(1, *w);
	*h = MAX(1, *h);
	if(interact) {
		if(*x > _sw)
			*x = _sw - WIDTH(c);
		if(*y > _sh)
			*y = _sh - HEIGHT(c);
		if(*x + *w + 2 * c->bw < 0)
			*x = 0;
		if(*y + *h + 2 * c->bw < 0)
			*y = 0;
	}
	else {
		if(*x > m->mx + m->mw)
			*x = m->mx + m->mw - WIDTH(c);
		if(*y > m->my + m->mh)
			*y = m->my + m->mh - HEIGHT(c);
		if(*x + *w + 2 * c->bw < m->mx)
			*x = m->mx;
		if(*y + *h + 2 * c->bw < m->my)
			*y = m->my;
	}
	if(*h < _bh)
		*h = _bh;
	if(*w < _bh)
		*w = _bh;
	if(resizehints || c->isfloating) {
		/* see last two sentences in ICCCM 4.1.2.3 */
		baseismin = c->basew == c->minw && c->baseh == c->minh;
		if(!baseismin) { /* temporarily remove base dimensions */
			*w -= c->basew;
			*h -= c->baseh;
		}
		/* adjust for aspect limits */
		if(c->mina > 0 && c->maxa > 0) {
			if(c->maxa < (float)*w / *h)
				*w = *h * c->maxa + 0.5;
			else if(c->mina < (float)*h / *w)
				*h = *w * c->mina + 0.5;
		}
		if(baseismin) { /* increment calculation requires this */
			*w -= c->basew;
			*h -= c->baseh;
		}
		/* adjust for increment value */
		if(c->incw)
			*w -= *w % c->incw;
		if(c->inch)
			*h -= *h % c->inch;
		/* restore base dimensions */
		*w += c->basew;
		*h += c->baseh;
		*w = MAX(*w, c->minw);
		*h = MAX(*h, c->minh);
		if(c->maxw)
			*w = MIN(*w, c->maxw);
		if(c->maxh)
			*h = MIN(*h, c->maxh);
	}
	return *x != c->x || *y != c->y || *w != c->w || *h != c->h;
}

-resize :(Client*)c :(int)x :(int)y :(int)w :(int)h :(Bool)interact
{
	if([self applySizeHints :c :&x :&y :&w :&h :interact]) {
		return [self resizeclient :c :x :y :w :h];
	}
	return self;
}

-resizeclient :(Client*)c :(int)x :(int)y :(int)w :(int) h
{
	XWindowChanges wc;

	c->oldx = c->x; c->x = wc.x = x;
	c->oldy = c->y; c->y = wc.y = y;
	c->oldw = c->w; c->w = wc.width = w;
	c->oldh = c->h; c->h = wc.height = h;
	wc.border_width = c->bw;
	//XConfigureWindow(_display, c->win, CWX|CWY|CWWidth|CWHeight|CWBorderWidth, &wc);
	[self configure :c];
	XSync(_display, False);
	return self;
}
#endif

-(Display*)getDisplay
{
	return _display;
}

-(Atom)getNetAtom:(int)name
{
	return _netatom[name];
}

-scan
{
	unsigned int i, num;
	Window d1, d2, *wins = NULL;
	XWindowAttributes wa;

	if (0 == XQueryTree(_display, _root, &d1, &d2, &wins, &num)) {
		fprintf(stderr, "XQueryTree fail\n");
		return self;
	}
	
	for(i = 0; i < num; i++) {
		if (!XGetWindowAttributes(_display, wins[i], &wa)
			|| wa.override_redirect || XGetTransientForHint(_display, wins[i], &d1)) {
			continue;
		}
		if (wa.map_state == IsViewable || 
			[self getWindowLong :wins[i]] == IconicState) {
				[[OwmClient alloc] initWithAttach :self  :wins[i] :&wa];
		}
	}
	for(i = 0; i < num; i++) {
		if (!XGetWindowAttributes(_display, wins[i], &wa)) {
			continue;
		}
		if (XGetTransientForHint(_display, wins[i], &d1) &&
			(wa.map_state == IsViewable || [self getWindowLong :wins[i]] == IconicState)) {
				[[OwmClient alloc] initWithAttach :self  :wins[i] :&wa];
		}
	}
	if (wins) {
		XFree(wins);
	}
	return self;
}

-createWm
{
	XSetWindowAttributes wa;

	_screen = DefaultScreen(_display);
	_root = RootWindow(_display, _screen);
	
	_sw = DisplayWidth(_display, _screen);
	_sh = DisplayHeight(_display, _screen);
	_bh = 24;
	[self updateGeom];
	XInternAtoms(_display, 
			atom_names, sizeof _wmatom / sizeof _wmatom[0], False, _wmatom);
	XInternAtoms(_display, 
			net_atom_names, sizeof _netatom / sizeof _netatom[0], False, _netatom);

	
	_dc.norm[ColBorder] = [self createColor :normbordercolor];
	_dc.norm[ColBG] = [self createColor :normbgcolor];
	_dc.norm[ColFG] = [self createColor :normfgcolor];
	_dc.sel[ColBorder] = [self createColor :selbordercolor];
	_dc.sel[ColBG] = [self createColor :selbgcolor];
	_dc.sel[ColFG] = [self createColor :selfgcolor];
	_dc.drawable = XCreatePixmap(
			_display, 
			_root, 
			DisplayWidth(_display, _screen), 128, DefaultDepth(_display, _screen));
	_dc.gc = XCreateGC(_display, _root, 0, NULL);
	XSetLineAttributes(_display, _dc.gc, 1, LineSolid, CapButt, JoinMiter);

	[self updateBorders];
	XChangeProperty(_display, _root, _netatom[Xn_NET_SUPPORTED], XA_ATOM, 32,
						PropModeReplace, (unsigned char *) _netatom, Xn_NET_MAX);

	wa.cursor = XCreateFontCursor(_display, XC_left_ptr);
	wa.event_mask = SubstructureRedirectMask|SubstructureNotifyMask|ButtonPressMask
	                |EnterWindowMask|LeaveWindowMask|StructureNotifyMask
	                |PropertyChangeMask;
	XChangeWindowAttributes(_display, _root, CWEventMask|CWCursor, &wa);
	XSelectInput(_display, _root, wa.event_mask);
	fprintf(stderr, "init SW=%d SH=%d\n", _sw, _sh);
	return self;
}

-onMapRequest :(XEvent*)e
{
	static XWindowAttributes wa;
	XMapRequestEvent *ev = &e->xmaprequest;

	if(!XGetWindowAttributes(_display, ev->window, &wa))
			return self;
	if(wa.override_redirect)
			return self;
	if(![self findClient :ev->window]) {
		 [[OwmClient alloc] initWithAttach :self :ev->window :&wa];
	}
	return self;
}

-run 
{
	XEvent ev;
	XSync(_display, False);
	while(!XNextEvent(_display, &ev)) {
		switch(ev.type)
		{
			case ButtonPress:
				fprintf(stderr,"Xe=ButtonPress\n"); break;
			case ClientMessage:
				fprintf(stderr,"Xe=ClientMessage\n"); break;
			case ConfigureRequest:
				fprintf(stderr,"Xe=ConfigureRequest\n"); break;
			case ConfigureNotify:
				fprintf(stderr,"Xe=ConfigureNotify\n"); break;
			case DestroyNotify:
				fprintf(stderr,"Xe=DestroyNotify\n"); break;
			case EnterNotify:
				fprintf(stderr,"Xe=EnterNotify\n"); break;
			case Expose:
				fprintf(stderr,"Xe=Expose\n"); break;
			case FocusIn:
				fprintf(stderr,"Xe=FocusIn\n"); break;
			case KeyPress:
				fprintf(stderr,"Xe=KeyPress\n"); break;
			case MappingNotify:
				fprintf(stderr,"Xe=MappingNotify\n"); break;
			case MapRequest:
				[self onMapRequest :&ev];
				fprintf(stderr,"Xe=MapRequest\n"); break;
			case PropertyNotify:
				fprintf(stderr,"Xe=PropertyNotify\n"); break;
			case UnmapNotify:
				fprintf(stderr,"Xe=UnmapNotify\n"); break;
			default:
				fprintf(stderr,"Xe=%d\n",ev.type); break;
		}
	}	
	
	return self;
}
-destroyWm
{
	XSync(_display, False);
	XSetInputFocus(_display, PointerRoot, RevertToPointerRoot, CurrentTime);
	return self;
}

-(unsigned long)createColor :(const char*)name
{
	Colormap cmap = DefaultColormap(_display, _screen);
	XColor color;
	if(!XAllocNamedColor(_display, cmap, name, &color, &color)) {
		fprintf(stderr, "%s: failed color\n", name);
		return 0;
	}
	return color.pixel;
}

-(Bool)getRootPointer :(int*)x :(int*)y
{
	int di;
	unsigned int dui;
	Window dummy;
	return XQueryPointer(_display, _root, &dummy, &dummy, x, y, &di, &di, &dui);
}

-(int)procotlError :(Display*) disp :(XErrorEvent*) ev
{
	char err[1024];
	XGetErrorText(disp, ev->error_code, err, sizeof(err));
	fprintf(stderr, "X Error: %s\n", err);
	return 0;
}

@end


