#import "Xlocal.h"
#import <objc/Object.h>
#import "OwmTypes.h"
#import "OwmScreen.h"

@class OwmScreen;
@class OwmCore;
@interface OwmClient : Object
{
	char title[256];
	float mina, maxa;
	OwmRect _wndRect;
	OwmRect _oldRect;
	int basew, baseh, incw, inch, maxw, maxh, minw, minh;
	int bw, oldbw;
	unsigned int tags;
	Bool isfixed, isfloating, isurgent, oldstate;
	OwmScreen *mon;
	OwmCore	  *_core;
	
	Window	  _frame;
	Window	  _win;
}
-(OwmScreen*)getScreen;
-configure;
-createWmBorder;
-(Window)getWindow;
-(Window)getFrame;
-initWithAttach :(OwmCore*)core :(Window)w :(XWindowAttributes*)wa;
-(Bool)getWindowText :(char *)text :(unsigned int) size;

-grabStart;
-grabEnd;

@end

