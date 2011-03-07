.SUFFIXES: .o .m

CC=gcc
TARGET=owm

CFLAGS=-g -Wno-import -I/usr/include/X11
LFLAGS=
LIBS=-lobjc -lXm -lXt
OBJDIR=build

SRCS=Main.m OwmCore.m OwmWindow.m OwmScreen.m OwmClient.m OwmUtList.m
O1=$(SRCS:%.m=%.o)
OBJS=$(O1:%=$(OBJDIR)/%)


all:$(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LFLAGS) -o $(TARGET) $(OBJS) $(LIBS)

.m.o:
	$(CC) $(CFLAGS) -c  $< -o $@

$(OBJDIR)/%.o: %.m
	$(CC) $(CFLAGS) -c  $< -o $@


$(OBJS): $(OBJDIR)

$(OBJDIR):
	mkdir $(OBJDIR)

clean:
	- rm -f $(OBJS)
	- rm -f $(TARGET)
	- rm -f *.bak
	- rm -f *.BAK

