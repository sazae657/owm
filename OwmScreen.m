#import "Xlocal.h"
#import "OwmCore.h"
#import "OwmScreen.h"

@implementation OwmScreen

-init :(OwmCore*) core
{
	mgr = core;
	mx = my = mw = mh = 0; 
	clients = NULL;
	sel		= NULL;
	stack	= NULL;
	next	= NULL;
	return self;
}

-initWithWindow :(Window*)win
{
}

-initWithAxis :(int)x :(int)y
{
}

@end

