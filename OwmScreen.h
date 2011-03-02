#import "Xlocal.h"
#import <objc/Object.h>
#import "OwmClient.h"
@interface OwmScreen : Object
{
	int mx;
	int my;
	int mw;
	int mh;
	OwmCore	  *mgr;
	OwmClient *clients;
	OwmClient *sel;
	OwmClient *stack;
	OwmScreen *next;
}

-init :(OwmCore*) mgr;
-initWithWindow :(Window*)win;
-initWithAxis :(int)x :(int)y;

@end

