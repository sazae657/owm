#import "Xlocal.h"
#import "OwmCore.h"
#import "OwmClient.h"
#import "OwmScreen.h"
#define INRECT(X,Y,RC) ((X) >= (RC.x) && (X) < (RC.x) + (RC.w) && (Y) >= (RC.y) && (Y) < (RC.y) + (RC.h))

@implementation OwmScreen

-initWith :(OwmCore*) core
{
	_core = core;
	_rect.x		= 
		_rect.y = 
		_rect.w = 
		_rect.h = 0; 
	_clients =  [[OwmUtList alloc] init];
	return self;
}

-initWithWindow :(OwmCore*)ct  :(Window)win
{
	int x, y;
	id c;
	id m;

	[self initWith :ct];
	
	if (win == [_core rootWindow] && [_core getRootPointer :&x :&y]) {
		return [self initWithAxis :ct :x :y];
	}

	if((c = [_core findClient :win])) {
		return c;
	}
	return self; 
}

-initWithAxis :(OwmCore*)ct :(int)x :(int)y
{
	[self initWith :ct];
	OwmUtList* m;
	for(m = [_core screenList]; m; m = [m next]) {
		if(True == [[m get] isHitCursor :x :y]) {
			return m;
		}
	}
	return self;
}

-(Bool)isHitCursor :(int)x :(int)y
{
	if(INRECT(x, y, _rect)) {
		return True;
	}
	return False;
}

-(OwmRect*)getRect
{
	return &_rect;
}

-(OwmUtList*)getClients
{
	return _clients;
}

@end

