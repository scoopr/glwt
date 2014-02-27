#include <glwt_internal.h>

#include <GLWT/glwt_intrusive.h>

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <QuartzCore/QuartzCore.h>

@interface GLWTApplication : UIApplication <UIApplicationDelegate>
{
    GLWTWindow* mainWindow;
}

@end

@implementation GLWTApplication

-(void)applicationDidBecomeActive:(UIApplication *)application
{
//    NSLog(@"applicationDidBecomeActive");
}

-(void)applicationWillResignActive:(UIApplication *)application
{
//    NSLog(@"applicationWillResignActive");
}


-(void)applicationDidEnterBackground:(UIApplication *)application
{
    glwtAppPause(glwt.userdata);
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    glwtAppResume(glwt.userdata);
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    glwtAppPause(glwt.userdata);
    glwtAppStop(glwt.userdata);
    glwt.userdata = NULL;

    [(NSMutableSet*)glwt.ios.animating_views release];
}

-(void)displayLinkCallback:(CADisplayLink*)sender
{
    for(GLWTView* view in (NSMutableSet*)glwt.ios.animating_views)
    {
        GLWTWindowEvent e;
        e.window = view.glwtWindow;
        e.type = GLWT_WINDOW_EXPOSE;
        e.window->win_callback(e.window, &e, e.window->userdata);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    displayLink.paused = YES;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    glwt.ios.animating_views = [[NSMutableSet alloc] init];
    glwt.ios.displayLink = displayLink;

    mainWindow = glwtAppInit(0, NULL);



    glwtAppResume(glwt.userdata);

    return NO;
}


@end


int glwtAppMain(int argc, char *argv[])
{
    return UIApplicationMain(argc,argv, @"GLWTApplication", @"GLWTApplication");
}

int glwtInit(
             const GLWTConfig *config,
             void (*error_callback)(const char *msg, void *userdata),
             void *userdata
             )
{
    glwt.error_callback = error_callback;
    glwt.userdata = userdata;
    return 0;
}

void glwtQuit()
{
}


int glwtEventHandle(int wait)
{

    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);

    return 0;
}

void glwtAppTerminate()
{
}


int glwtSetContinousRedraw(GLWTWindow* win, int enable)
{
    NSMutableSet* views = glwt.ios.animating_views;
    if(enable)
    {
        [views addObject:win->ios.view];
    } else
    {
        [views removeObject:win->ios.view];
    }

    CADisplayLink* displayLink = glwt.ios.displayLink;
    if([views count] > 0)
    {
        displayLink.paused = NO;
    } else
    {
        displayLink.paused = YES;
    }
    return 0;
}


int main(int argc, char** argv)
{
    return UIApplicationMain(argc,argv, @"GLWTApplication", @"GLWTApplication");
}
