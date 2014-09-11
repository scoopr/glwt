#ifndef GLWT_INTRUSIVE_H
#define GLWT_INTRUSIVE_H

#include <GLWT/glwt.h>

extern GLWTWindow *glwtAppInit(int argc, char *argv[]); // user defined
extern void glwtAppStop();
extern void glwtAppPause();
extern void glwtAppResume();

void glwtAppTerminate();

#endif
