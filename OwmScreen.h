#import "Xlocal.h"
#import <objc/Object.h>
#import "OwmCore.h"
#import "OwmScreen.h"
#import "OwmClient.h"
#import "OwmUtList.h"
#import "OwmTypes.h"

@class OwmCore;

@interface OwmScreen : Object
{
	OwmRect _rect;
	OwmCore	  *_core;
	OwmUtList *_clients;
}

-(Bool)isHitCursor :(int)x :(int)y;
-initWith :(OwmCore*) mgr;
-initWithWindow :(OwmCore*) core :(Window)win;
-initWithAxis :(OwmCore*) core :(int)x :(int)y;

-(OwmRect*)getRect;

-(OwmUtList*)getClients;

@end


