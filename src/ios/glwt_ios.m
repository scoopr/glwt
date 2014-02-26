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
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

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




int main(int argc, char** argv)
{
    return UIApplicationMain(argc,argv, @"GLWTApplication", @"GLWTApplication");
}
