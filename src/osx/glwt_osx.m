#import <GLWT/glwt.h>
#import <glwt_internal.h>

#import <mach/mach_time.h>
#import <crt_externs.h> // for _NSGetProgname

@interface GLWTApplication : NSApplication <NSApplicationDelegate> {
}
@end



@implementation GLWTApplication
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [NSApp stop:nil];

    // http://www.cocoabuilder.com/archive/cocoa/219842-nsapp-stop.html
    NSEvent* event = [NSEvent otherEventWithType:NSApplicationDefined
                                        location:NSMakePoint(0,0)
                                   modifierFlags:0
                                       timestamp:0.0
                                    windowNumber:0
                                         context:nil
                                         subtype:0
                                           data1:0
                                           data2:0];

    [NSApp postEvent:event atStart:true];

}
@end





static int createPixelFormat(const GLWTConfig *config)
{
    if(config &&
       (config->api & GLWT_API_MASK) != GLWT_API_ANY &&
       (config->api & GLWT_API_MASK) != GLWT_API_OPENGL)
    {
        glwtErrorPrintf("NSOpenGL can only initialize OpenGL profiles");
        return -1;
    }

    if(config &&
       config->api_version_major >= 3 &&
       (config->api & GLWT_PROFILE_COMPATIBILITY) == GLWT_PROFILE_COMPATIBILITY)
    {
        glwtErrorPrintf("OS X does not support compatibility contexts");
        return -1;
    }

    if (config &&
        (config->api_version_major == 3 && config->api_version_minor < 2))
    {
        glwtErrorPrintf("OS X only supports legacy OpenGL versions up to 2.1 "
                        "and Core profile contexts starting from version 3.2");
        return -1;
    }

    glwt.api = config ? config->api : 0;
    glwt.api_version_major = config ? config->api_version_major : 0;
    glwt.api_version_minor = config ? config->api_version_minor : 0;

    int colorBits = 0;
    int core = 1;
    if(config)
    {
        colorBits = config->red_bits + config->green_bits + config->blue_bits;
        core = (config->api_version_major >= 3) || (config->api_version_major == 0);
    }

    NSOpenGLPixelFormatAttribute attribs[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, colorBits,
        NSOpenGLPFADepthSize, config ? config->depth_bits : 0,
        NSOpenGLPFAStencilSize, config ? config->stencil_bits : 0,
        NSOpenGLPFASampleBuffers, config ? config->sample_buffers : 0,
        NSOpenGLPFASamples, config ? config->samples : 0,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
        core ? NSOpenGLPFAOpenGLProfile : 0,
        core ? NSOpenGLProfileVersion3_2Core : 0,
#endif
        0
    };

    glwt.osx.pixel_format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    if(glwt.osx.pixel_format == nil)
    {
        glwtErrorPrintf("Failed to create NSOpenGLPixelFormat");
        return -1;
    }

    return 0;
}

static NSString * getApplicationName()
{
    size_t i;
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];

    NSString *possibleNameKeys[] =
    {
        @"CFBundleDisplayName",
        @"CFBundleName",
        @"CFBundleExecutable",
    };

    char **progname = _NSGetProgname();

    // See if the bundle provides a name for our app
    for (i = 0; i < sizeof(possibleNameKeys)/sizeof(possibleNameKeys[0]); ++i)
    {
        id name = [infoDict objectForKey:possibleNameKeys[i]];
        if (name && [name isKindOfClass:[NSString class]]
            && ![name isEqualToString:@""])
        {
            return name;
        }
    }

    // Try with process/executable name
    if (progname && *progname)
    {
        return [NSString stringWithUTF8String: *progname];
    }

    // Should never be reached
    return @"GLWT Application";
}

static void generateDefaultMenu()
{
    NSString *appName = getApplicationName();
    NSMenu *menubar = [[NSMenu alloc] init];
    [glwt.osx.app setMainMenu:menubar];

    NSMenuItem *appMenuItem =
        [menubar addItemWithTitle:@"" action:NULL keyEquivalent:@""];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];

    [appMenu addItemWithTitle:[NSString stringWithFormat:@"About %@", appName]
                       action:@selector(orderFrontStandardAboutPanel:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"Hide %@", appName]
                       action:@selector(hide:)
                keyEquivalent:@"h"];
    [[appMenu addItemWithTitle:@"Hide Others"
                       action:@selector(hideOtherApplications:)
                keyEquivalent:@"h"]
        setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
    [appMenu addItemWithTitle:@"Show All"
                       action:@selector(unhideAllApplications:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", appName]
                       action:@selector(terminate:)
                keyEquivalent:@"q"];

    NSMenuItem *windowMenuItem =
        [menubar addItemWithTitle:@"" action:NULL keyEquivalent:@""];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [glwt.osx.app setWindowsMenu:windowMenu];
    [windowMenuItem setSubmenu:windowMenu];

    [windowMenu addItemWithTitle:@"Minimize"
                          action:@selector(performMiniaturize:)
                   keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom"
                          action:@selector(performZoom:)
                   keyEquivalent:@""];
    [windowMenu addItemWithTitle:@"Bring All to Front"
                          action:@selector(arrangeInFront:)
                   keyEquivalent:@""];

    // Apparently this used to be declared in NSApplication.h
    [glwt.osx.app performSelector:@selector(setAppleMenu:) withObject:appMenu];
    [menubar release];
    [appMenu release];
    [windowMenu release];

}


int glwtInit(const GLWTConfig *config,
             void (*error_callback)(const char *msg, void *userdata),
             void *userdata)
{
    BOOL nibLoaded = NO;
    glwt.error_callback = error_callback;
    glwt.userdata = userdata;

    if(createPixelFormat(config) < 0)
        return -1;

    glwt.osx.autorelease_pool = [[NSAutoreleasePool alloc] init];
    glwt.osx.app = [GLWTApplication sharedApplication];
    [NSApp setDelegate:NSApp];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *mainNibName = [infoDictionary objectForKey:@"NSMainNibFile"];
    
    if([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)])
    {
        // 10.8 and up
        nibLoaded = [[NSBundle mainBundle] loadNibNamed:mainNibName owner:NSApp topLevelObjects:&glwt.osx.nib_toplevel];
    } else
    {
        // 10.7 and under (performSelector to avoid deprecation warnings)
        nibLoaded = (BOOL)[NSBundle performSelector:@selector(loadNibNamed:owner:) withObject:mainNibName withObject:NSApp];
    }
    [glwt.osx.nib_toplevel retain];

    if(!nibLoaded)
    {
        // TODO: don't generate menu on iOS?
        generateDefaultMenu();
    }

    [NSApp run];
    // should resume immediately after applicationDidFinishLaunching

    /*
     If ran outside of application bundle, system assumes a
     command-line application or similiar. Tell system that we
     are actually a gui application that likes to have a dock icon etc.
     */
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    [glwt.osx.app activateIgnoringOtherApps: YES];


    [NSEvent setMouseCoalescingEnabled:NO];

    return 0;
}

void glwtQuit()
{
    [glwt.osx.nib_toplevel release];
    if (glwt.osx.app)
    {
        [glwt.osx.app stop:nil];
        [glwt.osx.app release];
        glwt.osx.app = nil;
    }
    if(glwt.osx.autorelease_pool)
    {
        [glwt.osx.autorelease_pool drain];
        glwt.osx.autorelease_pool = nil;
    }
}

int glwtEventHandle(int wait)
{
    int events_handled = 0;
    do
    {
        NSEvent* event = [
            glwt.osx.app nextEventMatchingMask: NSAnyEventMask
            untilDate: wait ? [NSDate distantFuture] : nil
            inMode: NSDefaultRunLoopMode
            dequeue: YES];

        if(event)
        {
            if ([event type] == NSKeyUp && ([event modifierFlags] & NSCommandKeyMask))
                [[glwt.osx.app keyWindow] sendEvent:event];
            else
                [glwt.osx.app sendEvent:event];

            events_handled++;
        }
    } while(events_handled == 0 && wait);

    [glwt.osx.autorelease_pool drain];
    glwt.osx.autorelease_pool = [NSAutoreleasePool new];

    return 0;
}

double glwtGetTime()
{
    mach_timebase_info_data_t time_info;

    // query mach_absolute_time frequency
    mach_timebase_info(&time_info);

    return (double)mach_absolute_time() * ((double)time_info.numer / (double)time_info.denom) * 1e-9;
}
