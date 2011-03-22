
typedef struct _tagOwmRect {
	int x;
	int y;
	int w;
	int h;
}OwmRect;

enum { CurNormal, CurResize, CurMove, CurLast };        /* cursor */
enum { ColBorder, ColFG, ColBG, ColLast };              /* color */
enum { 
	Xs_MIT_PRIORITY_COLORS,
	Xs_WM_CHANGE_STATE,
	Xs_WM_STATE,
	Xs_WM_COLORMAP_WINDOWS,
	Xs_WM_PROTOCOLS,
	Xs_WM_TAKE_FOCUS,
	Xs_WM_SAVE_YOURSELF,
	Xs_WM_DELETE_WINDOW,
	Xs_SM_CLIENT_ID,
	Xs_WM_CLIENT_LEADER,
	Xs_WM_WINDOW_ROLE,
	Xn_NET_SUPPORTED,
	Xn_NET_WM_NAME,
	Xn_NET_WM_STATE,
	Xn_NET_WM_STATE_FULLSCREEN,
	Xs_ATOM_MAX
};


enum { ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle,
	       ClkClientWin, ClkRootWin, ClkLast };
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

