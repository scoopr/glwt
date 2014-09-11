#include <stdio.h>
#include <stdlib.h>

#include <GLWT/glwt.h>
#include <GLWT/glwt_intrusive.h>

#ifdef GLWT_TEST_GLES
#include <GLXW/glxw_es2.h>
#else
#include <GLXW/glxw.h>
#endif

#ifdef ANDROID
#include <android/log.h>
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, __FILE__, __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, __FILE__, __VA_ARGS__))
#else
#define LOGI(...) ((void)fprintf(stdout, __VA_ARGS__))
#define LOGW(...) ((void)fprintf(stderr, __VA_ARGS__))
#endif

static void error_callback(const char *msg)
{
#ifdef ANDROID
    LOGW(msg);
#else
    fprintf(stderr, "%s\n", msg);
#endif
}

static void event_callback(const GLWTEvent *event)
{

    switch(event->type)
    {
        case GLWT_WINDOW_CLOSE:
            LOGI("Window closed\n");
            break;
        case GLWT_WINDOW_SURFACE_CREATE:
            LOGI("Surface create\n");
            glwtMakeCurrent(event->window);

            if(glxwInit() != 0)
            {
                LOGW("glxwInit failed\n");
                glwtAppTerminate();
            }

            break;

        case GLWT_WINDOW_SURFACE_DESTROY:
            LOGI("Surface destroy\n");
            glwtMakeCurrent(0);
            break;

        case GLWT_WINDOW_EXPOSE:
            LOGI("Window exposed\n");
            {
                int width, height;
                glwtWindowGetSize(event->window, &width, &height);
                LOGI("**** window size: %d x %d\n", width, height);

                glClearColor(0.2, 0.4, 0.7, 1.0);
                glClear(GL_COLOR_BUFFER_BIT);

                glwtSwapBuffers(event->window);
            }
            break;
        case GLWT_WINDOW_RESIZE:
            LOGI("Window resized  width: %d  height: %d\n", event->resize.width, event->resize.height);
            break;
        case GLWT_WINDOW_SHOW:
        case GLWT_WINDOW_HIDE:
            LOGI("Window %s\n", (event->type == GLWT_WINDOW_SHOW) ? "show" : "hide");
            break;
        case GLWT_WINDOW_FOCUS_IN:
        case GLWT_WINDOW_FOCUS_OUT:
            LOGI("Window focus %s\n", (event->type == GLWT_WINDOW_FOCUS_IN) ? "in" : "out");
            break;
        case GLWT_KEY_PRESS:
        case GLWT_KEY_RELEASE:
            LOGI("Key %s  keysym: 0x%x  scancode: %d  mod: %X\n",
                (event->type == GLWT_KEY_PRESS) ? "down" : "up",
                event->key.keysym, event->key.scancode, event->key.mod);
            break;
        case GLWT_BUTTON_PRESS:
        case GLWT_BUTTON_RELEASE:
            LOGI("Button %s  x: %d  y: %d  button: %d  mod: %X\n",
                (event->type == GLWT_BUTTON_PRESS) ? "down" : "up",
                event->button.x, event->button.y, event->button.button, event->button.mod);
            break;
        case GLWT_MOUSE_MOTION:
            LOGI("Motion  x: %d  y: %d  buttons: %X\n",
                event->motion.x, event->motion.y, event->motion.buttons);
            break;
        case GLWT_WINDOW_MOUSE_ENTER:
        case GLWT_WINDOW_MOUSE_LEAVE:
            LOGI("Mouse %s\n", (event->type == GLWT_WINDOW_MOUSE_ENTER) ? "enter" : "leave");
            break;
        case GLWT_TOUCH_BEGIN:
        case GLWT_TOUCH_MOVE:
        case GLWT_TOUCH_END:
        case GLWT_TOUCH_CANCEL:
            {
                const char* type_names[] = {
                    "begin",
                    "move",
                    "end",
                    "cancel"
                };
                LOGI("Touch %s x: %f y: %f id: %d\n", type_names[event->type - GLWT_TOUCH_BEGIN], 
                                           event->touch.x, event->touch.y, event->touch.touch_id);
            }
            break;
        default:
            break;
    }
}

struct my_app_state {
// this is global state
};

void glwtAppStop() {
}

void glwtAppPause() {
}

void glwtAppResume() {
}

GLWTWindow *glwtAppInit(int argc, char *argv[])
{
    (void)argc;
    (void)argv;

    GLWTConfig glwt_config = {
        0, 0, 0, 0,
        0, 0,
        0, 0,
        GLWT_API_ANY | GLWT_PROFILE_DEBUG,
        2, 0
    };
    
//    struct my_app_state* app_state = calloc(sizeof(struct my_app_state), 1);
    

    if(glwtInit(&glwt_config, event_callback, error_callback) != 0)
        return 0;

    return glwtWindowCreate("", 400, 300, NULL, NULL);
}
