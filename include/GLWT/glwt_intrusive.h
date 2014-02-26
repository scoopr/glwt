#ifndef GLWT_INTRUSIVE_H
#define GLWT_INTRUSIVE_H

#include <GLWT/glwt.h>

extern GLWTWindow *glwtAppInit(int argc, char *argv[]); // user defined
extern void glwtAppStop(void *userdata);
extern void glwtAppPause(void *userdata);
extern void glwtAppResume(void *userdata);

void glwtAppTerminate();

#endif
