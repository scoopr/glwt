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
    glwtAppPause();
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    glwtAppResume();
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    glwtAppPause();
    glwtAppStop();
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    mainWindow = glwtAppInit(0, NULL);
    glwtAppResume();

    return NO;
}


@end


int glwtAppMain(int argc, char *argv[])
{
    return UIApplicationMain(argc,argv, @"GLWTApplication", @"GLWTApplication");
}

int glwtInit(
             const GLWTConfig *config,
             void (*event_callback)(const GLWTEvent *event),
             void (*error_callback)(const char *msg)
             )
{
    // TODO: config
    glwt.event_callback = event_callback;
    glwt.error_callback = error_callback;
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
