#ifndef GLWT_glwt_ios_h
#define GLWT_glwt_ios_h

#if defined(__OBJC__)
#import <UIKit/UIKit.h>
@interface GLWTView : UIView
{
    GLWTWindow* glwtWindow;
}
@property (assign) GLWTWindow* glwtWindow;

+(id)layerClass;

@end
#endif

enum glwt_color_format
{
    glwt_color_format_565 = 565,
    glwt_color_format_8888 = 8888
};


struct glwt_ios
{
    void* displayLink;
    void* animating_views;
};

struct glwt_fbo_ios
{
    unsigned int fbo;
    unsigned int colorBuffer;
    unsigned int depthBuffer;
    int width, height;
    enum glwt_color_format colorFormat;
    int depthFormat;
};

struct glwt_window_ios
{
    void *uiwindow;
    void *eaglcontext;
    void *view;
    struct glwt_fbo_ios fbo;
};


int glwtSetRenderbufferAsDrawable(void* context, void* layer, enum glwt_color_format format);
int glwtCreateFBOWithDrawable(void* context, void* layer, enum glwt_color_format format, int depthComponent, struct glwt_fbo_ios* out);
int glwtDeleteFBO(struct glwt_fbo_ios* fbo);
int glwtRecreateSurface(GLWTWindow* win);

#endif
