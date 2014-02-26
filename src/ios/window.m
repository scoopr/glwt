#include <glwt_internal.h>

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/ES2/gl.h>

@interface GLWTView : UIView
{
    GLWTWindow* glwtWindow;
    CADisplayLink* displayLink;
}
@property (assign) GLWTWindow* glwtWindow;

+(id)layerClass;

@end


@implementation GLWTView

@synthesize glwtWindow;

-(id)init
{
    CGRect frame = {0};
    self = [super initWithFrame:frame];
    if(self)
    {
        self.glwtWindow = nil;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentMode = UIViewContentModeScaleToFill;
        self.multipleTouchEnabled = YES;
        // TODO: enable display link for continous display update
        // displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback)];
        // [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

+(id)layerClass
{
    return [CAEAGLLayer class];
}

-(void)displayLinkCallback
{
    // TODO: send expose event
}

- (void)drawRect:(CGRect)rect
{
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
    {
        CGPoint loc = [touch locationInView:self];
        // CGPoint prevloc = [touch previousLocationInView:self];
        GLWTWindowEvent ev;
        ev.type = GLWT_WINDOW_TOUCH_BEGIN;
        ev.touch.x = loc.x;
        ev.touch.y = loc.y;
        ev.touch.touch_id = (int)touch;
        glwtWindow->win_callback(glwtWindow, &ev, glwtWindow->userdata);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
    {
        CGPoint loc = [touch locationInView:self];
        // CGPoint prevloc = [touch previousLocationInView:self];
        GLWTWindowEvent ev;
        ev.type = GLWT_WINDOW_TOUCH_MOVE;
        ev.touch.x = loc.x;
        ev.touch.y = loc.y;
        ev.touch.touch_id = (int)touch;
        glwtWindow->win_callback(glwtWindow, &ev, glwtWindow->userdata);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
    {
        CGPoint loc = [touch locationInView:self];
        // CGPoint prevloc = [touch previousLocationInView:self];
        GLWTWindowEvent ev;
        ev.type = GLWT_WINDOW_TOUCH_END;
        ev.touch.x = loc.x;
        ev.touch.y = loc.y;
        ev.touch.touch_id = (int)touch;
        glwtWindow->win_callback(glwtWindow, &ev, glwtWindow->userdata);
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
    {
        CGPoint loc = [touch locationInView:self];
        // CGPoint prevloc = [touch previousLocationInView:self];
        GLWTWindowEvent ev;
        ev.type = GLWT_WINDOW_TOUCH_CANCEL;
        ev.touch.x = loc.x;
        ev.touch.y = loc.y;
        ev.touch.touch_id = (int)touch;
        glwtWindow->win_callback(glwtWindow, &ev, glwtWindow->userdata);
    }
}



@end


@interface GLWTViewController : UIViewController

@end

@implementation GLWTViewController

- (id)init
{
    if((self = [super init]))
    {
//        self.wantsFullScreenLayout = YES;
    }
    return self;
}

-(void)loadView
{
//    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    self.view = [[[GLWTView alloc] init] autorelease];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    GLWTWindow* glwtWindow = ((GLWTView*)self.view).glwtWindow;

    // TODO: don't recreate when the same size
    glwtRecreateSurface(glwtWindow);

    GLWTWindowEvent ev;
    ev.type = GLWT_WINDOW_RESIZE;
    glwtWindowGetSize(glwtWindow, &ev.resize.width, &ev.resize.height);

    glwtWindow->win_callback(glwtWindow, &ev, glwtWindow->userdata);
    
}

@end


int glwtSetRenderbufferAsDrawable(void* vcontext, void* vlayer, enum glwt_color_format format)
{
    EAGLContext* context = (EAGLContext*)vcontext;
    CAEAGLLayer* layer = (CAEAGLLayer*)vlayer;

    NSString* colorFormat = kEAGLColorFormatRGBA8;

    switch(format)
    {
        case glwt_color_format_565:
            colorFormat = kEAGLColorFormatRGB565;
            break;
        case glwt_color_format_8888:
            colorFormat = kEAGLColorFormatRGBA8;
            break;
    }

    NSDictionary* properties = [NSDictionary dictionaryWithObject:colorFormat forKey:kEAGLDrawablePropertyColorFormat];
    layer.drawableProperties = properties;

    BOOL succ = [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    return succ;
}

int glwtCreateFBOWithDrawable(void* context, void* layer, enum glwt_color_format format, int depthComponent, struct glwt_fbo_ios* out)
{

    struct glwt_fbo_ios res;
    memset(&res, 0, sizeof(struct glwt_fbo_ios));


    glGenFramebuffers(1, &res.fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, res.fbo);

    glGenRenderbuffers(1, &res.colorBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, res.colorBuffer);
    int succ = glwtSetRenderbufferAsDrawable(context, layer, format);

    if(!succ) { res.fbo=0; return 0; }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, res.colorBuffer);

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &res.width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &res.height);

    if(depthComponent != 0)
    {
        glGenRenderbuffers(1, &res.depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, res.depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, res.width, res.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, res.depthBuffer);
    }

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;

    if(status != GL_FRAMEBUFFER_COMPLETE) {
        glwtErrorPrintf("Failed to make complete framebuffer object %x", status);
    }

    glBindRenderbuffer(GL_RENDERBUFFER, res.colorBuffer);

    res.colorFormat = format;
    res.depthFormat = depthComponent;

    *out = res;

    return 1;
}

int glwtDeleteFBO(struct glwt_fbo_ios* fbo)
{
    if(fbo->colorBuffer) glDeleteRenderbuffers(1, &fbo->colorBuffer);
    if(fbo->depthBuffer) glDeleteRenderbuffers(1, &fbo->depthBuffer);
    fbo->colorBuffer = 0;
    fbo->depthBuffer = 0;
    fbo->width = 0;
    fbo->height = 0;
    return 0;
}

int glwtRecreateSurface(GLWTWindow* win)
{
    glwtDeleteFBO(&win->ios.fbo);

    EAGLContext* ctx = win->ios.eaglcontext;
    CAEAGLLayer* layer = (CAEAGLLayer*)[(GLWTView*)win->ios.view layer];
    glwtCreateFBOWithDrawable(ctx, layer, win->ios.fbo.colorFormat, 
                                          win->ios.fbo.depthFormat, 
                                          &win->ios.fbo);
    
    return 0;
}


GLWTWindow *glwtWindowCreate(const char *title,
                             int width, int height,
                             GLWTWindow *share,
                             void (*win_callback)(GLWTWindow *window, const GLWTWindowEvent *event, void *userdata),
                             void *userdata)
{
    (void)title; // Not used
    (void)width;
    (void)height; // Size is forced

    GLWTWindow* win = calloc(1, sizeof(GLWTWindow));
    if(!win) return NULL;
    win->win_callback = win_callback;



    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:nil];

    if(context == nil)
    {
        glwtErrorPrintf("No GLES2 Context available, bailing");
        glwtWindowDestroy(win);
        return NULL;
    }

    UIScreen* screen = [UIScreen mainScreen];
    
    // TODO: how to choose external display
    // UIScreen* screen = [[UIScreen screens] objectAtIndex:i];
    
    // TODO: this should probably be controlled by fullscreen flag
    // [UIApplication sharedApplication].statusBarHidden = YES;
    
    // TODO: retina contentScaleFactor
    
    // TODO: this doesn't take the initial orientation in to account
    UIWindow* uiwindow = [[UIWindow alloc] initWithFrame:[screen bounds]];
    
    GLWTViewController* viewController = [[[GLWTViewController alloc] init] autorelease];
    GLWTView* view = (GLWTView*)viewController.view;
    view.frame = uiwindow.frame;
    view.glwtWindow = win;
    
    UINavigationController* navController = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
    navController.navigationBarHidden = YES;
    uiwindow.rootViewController = navController;

    CAEAGLLayer* layer = (CAEAGLLayer*)viewController.view.layer;

    [EAGLContext setCurrentContext:context];
    glwtCreateFBOWithDrawable(context, layer, glwt_color_format_565, GL_DEPTH_COMPONENT16, &win->ios.fbo);

    layer.opaque = YES;
    win->ios.uiwindow = uiwindow;
    win->ios.eaglcontext = context;
    win->ios.view = view;
    win->userdata = userdata;
    
    if(win->win_callback)
    {
        GLWTWindowEvent event;
        event.window = win;
        event.type = GLWT_WINDOW_SURFACE_CREATE;
        event.dummy.dummy = 0;
        win->win_callback(win, &event, win->userdata);

        event.window = win;
        event.type = GLWT_WINDOW_EXPOSE;
        event.dummy.dummy = 0;
        win->win_callback(win, &event, win->userdata);
    }

    [uiwindow makeKeyAndVisible];

    return win;
}

int glwtMakeCurrent(GLWTWindow *win)
{
    EAGLContext* ctx = nil;
    if(win) ctx = win->ios.eaglcontext;

    BOOL ret = [EAGLContext setCurrentContext:ctx];
    return ret == YES ? 0 : -1;
}

void glwtWindowDestroy(GLWTWindow *window)
{
    if(!window) return;
    glwtDeleteFBO(&window->ios.fbo);
    [(UIWindow*)window->ios.uiwindow release];
    free(window);
}

void glwtWindowShow(GLWTWindow *window, int show)
{
    // FIXME: It is debatable if hiding window is at all useful.
    UIWindow* uiwin = (UIWindow*)window->ios.uiwindow;
    if(show) [uiwin makeKeyAndVisible];
    else uiwin.hidden = YES;
}

int glwtWindowGetSize(GLWTWindow *win, int *width, int *height)
{
    *width = win->ios.fbo.width;
    *height = win->ios.fbo.height;
    return 0;
}

void glwtWindowSetTitle(GLWTWindow *win, const char *title)
{
    (void)win;
    (void)title;
    // No window titles on iOS
}


int glwtSwapBuffers(GLWTWindow *win)
{
    BOOL ret = [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    return ret == YES ? 0 : -1;
}

int glwtSwapInterval(GLWTWindow *win, int interval)
{
    return 0;
}
