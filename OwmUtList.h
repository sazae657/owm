#import "Xlocal.h"
#import <objc/Object.h>

typedef struct _tagOwmUtListRec
{
	id item;
	struct _tagOwmUtListRec *next;
	struct _tagOwmUtListRec *prev;
}OwmUtListRec;


@interface OwmUtList : Object
{
	OwmUtListRec *_first;
	OwmUtListRec *_end;
	OwmUtListRec *_cursor;
}

-init;
-add :(id)item;
-(id)get;
-(id)next;
-(id)reset;
-(id)first;
@end

