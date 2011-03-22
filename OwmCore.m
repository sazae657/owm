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
	"_NET_SUPPORTED",
	"_NET_WM_NAME",
	"_NET_WM_STATE",
	"_NET_WM_STATE_FULLSCREEN",
    NULL
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

-(OwmClient*)findClientByFrame :(Window)w
{
	OwmUtList *c;
	OwmUtList *m;
	for (m = [self screenList]; NULL != m; m = [m next]) {
		for (c = [[m get] getClients]; NULL != c; c = [c next]) {
			if([[c get] getFrame] == w) {
				return [c get];
			}
            else {
                fprintf(stderr, "FFF NoMatch %x == %x\n", w, [[c get] getFrame]);
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

-focus :(OwmClient*)c
{
	if(c) {
		//if(c->isurgent)
		//	clearurgent(c);
		// grabbuttons(c, True);
		//XSetWindowBorder(_display, c->win, _dc.sel[ColBorder]);
		XMapRaised(_display, [c getFrame]);
		//XRaiseWindow(_display, [c getFrame]);
		XSetInputFocus(_display, [c getWindow], RevertToPointerRoot, CurrentTime);	
	}
	else {
		XSetInputFocus(_display, _root, RevertToPointerRoot, CurrentTime);
	}
	return self;
}

-unfocus :(OwmClient*)c :(Bool)setfocus
{
	if(!c) return self;
	//grabbuttons(c, False);
	//XSetWindowBorder(_display, [c getwin, _dc.norm[ColBorder]);
	if (setfocus) {
		XSetInputFocus(_display, _root, RevertToPointerRoot, CurrentTime);
	}
	return self;
}

#if 0
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

-(Atom)getWmAtom:(int)name
{
	return _wmatom[name];
}

-scan
{
	unsigned int i, num;
	Window d1, d2, *wins = NULL;
	XWindowAttributes wa;
	OwmClient *cl = NULL;
	OwmUtList *lst = [[_mons get] getClients];

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
			[lst add :[[OwmClient alloc] initWithAttach :self  :wins[i] :&wa]];
		}
	}
	for(i = 0; i < num; i++) {
		if (!XGetWindowAttributes(_display, wins[i], &wa)) {
			continue;
		}
		if (XGetTransientForHint(_display, wins[i], &d1) &&
			(wa.map_state == IsViewable || [self getWindowLong :wins[i]] == IconicState)) 
		{
			[lst add :[[OwmClient alloc] initWithAttach :self  :wins[i] :&wa]];
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
    
    int i = 0;
    for ( ; NULL != atom_names[i]; ++i) {
        _wmatom[i] = XInternAtom(_display, atom_names[i], False);
    }

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

	//[self updateBorders];
	//XChangeProperty(_display, _root, _wmatom[Xn_NET_SUPPORTED], XA_ATOM, 32,
	//					PropModeReplace, (unsigned char *) _netatom, Xn_NET_MAX);

	wa.cursor = XCreateFontCursor(_display, XC_left_ptr);
	wa.event_mask = SubstructureRedirectMask 
					| SubstructureNotifyMask | ColormapChangeMask
					| ButtonPressMask | ButtonReleaseMask | PropertyChangeMask;
	                
	XChangeWindowAttributes(_display, _root, CWEventMask|CWCursor, &wa);
	XSync(_display, False);
	XSelectInput(_display, _root, wa.event_mask);
	_activeClient = NULL;
	fprintf(stderr, "init SW=%d SH=%d\n", _sw, _sh);
	return self;
}

-(unsigned long) getColor :(int)index
{
	return _dc.norm[index];
}

-onMapRequest :(XEvent*)e
{
	static XWindowAttributes wa;
	XMapRequestEvent *ev = &e->xmaprequest;
	OwmUtList* lst = [[_mons get] getClients];
	
	OwmClient* cl = NULL;
	if(!XGetWindowAttributes(_display, ev->window, &wa))
			return self;
	if(wa.override_redirect)
			return self;
	if(NULL == (cl = [self findClient :ev->window])) {
		[lst add :[[OwmClient alloc] initWithAttach :self :ev->window :&wa]];
	}
	else {
		XMapRaised(_display, [cl getFrame]);
		XMapWindow(_display, [cl getWindow]);
	}
	return self;
}

-onMouseButtonPress:(XEvent*)e
{
	XButtonEvent *ev = &e->xbutton;
	OwmClient* c;
	_activeClient = NULL;	
	if(_root == ev->window) {
		fprintf(stderr, "root windows hit\n");
	}

	if (NULL == (c = [self findClientByFrame: ev->window])) {
		fprintf(stderr, "frame not match\n");
		if(NULL == (c = [self findClient: ev->window])) {
			fprintf(stderr, "client not match\n");
		}
        fprintf(stderr, "Unknowon Window: %x\n", ev->window);
		return self;
	}
	
	fprintf(stderr, "frame found\n");
	_activeClient = c;
	[self focus :_activeClient];
	[_activeClient grabStart];
}
-onMouseButtonRelease:(XEvent*)e
{
	if (_activeClient) {
		[_activeClient grabEnd];
		_activeClient = NULL;
	}
}

-onConfigureRequest:(XEvent*)e
{
	XConfigureRequestEvent *ev = &e->xconfigurerequest;
	XWindowAttributes wa;
	OwmClient *c = [self findClient :ev->window];
	if(c) {
		fprintf(stderr, "ConfigureRequest: match\n");
		[c configure :ev];
		return self;
	}
	OwmUtList* lst = [[_mons get] getClients];
	XGetWindowAttributes(_display, ev->window, &wa);
	fprintf(stderr, "ConfigureRequest: not match\n");
	OwmClient *cl = [[[OwmClient alloc] initWithAttach :self :ev->window :&wa] configure:ev]; 
	[lst add :cl];
}

-onUnmapNotify:(XEvent*)e
{
	XUnmapEvent *ev = &e->xunmap;
	OwmClient* c = [self findClient :ev->window];
	if(NULL == c) {
		fprintf(stderr, "UnmapNotify: not match\n");
        return self;
	}
	
	fprintf(stderr, "UnmapNotify: match\n");
    //[c reparent];
}

-run 
{
	XEvent ev;
	XSync(_display, False);
	while(!XNextEvent(_display, &ev)) {
		switch(ev.type)
		{
			case ButtonPress:
				[self onMouseButtonPress :&ev];
				fprintf(stderr,"Xe=ButtonPress\n"); break;
			case ButtonRelease:
				[self onMouseButtonRelease :&ev];
				fprintf(stderr,"Xe=ButtonRelease\n"); break;
			case ClientMessage:
				fprintf(stderr,"Xe=ClientMessage\n"); break;
			case ConfigureRequest:
				[self onConfigureRequest :&ev];
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
				[self onUnmapNotify :&ev];
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


