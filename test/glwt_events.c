#include <stdio.h>
#include <ctype.h>

#include <GLWT/glwt.h>

#ifdef GLWT_TESTS_GLES
#include <GLXW/glxw_es2.h>
#else
#include <GLXW/glxw.h>
#endif

static int encode_utf8(unsigned int codepoint, unsigned char *out)
{
    if((codepoint & ~0x7F) == 0)
    {
        out[0] = (codepoint & 0x7F);
        return 1;
    } else if((codepoint & ~0x7FF) == 0)
    {
        out[0] = (0xc0 | (codepoint & 0x7C0) >> 6);
        out[1] = (0x80 | (codepoint & 0x3F));
        return 2;
    } else if((codepoint & ~0xFFFF) == 0)
    {
        out[0] = (0xe0 | (codepoint & 0xF000) >> 12);
        out[1] = (0x80 | (codepoint & 0xFC) >> 6);
        out[2] = (0x80 | (codepoint & 0x3F));
        return 3;
    } else if((codepoint & ~0x3FFFF) == 0)
    {
        out[0] = (0xf0 | (codepoint & 0x1c0000) >> 18);
        out[1] = (0x80 | (codepoint & 0x3f00) >> 12);
        out[2] = (0x80 | (codepoint & 0xFC) >> 6);
        out[3] = (0x80 | (codepoint & 0x3F));
        return 4;
    }

    return 0;
}

static void error_callback(const char *msg, void *userdata)
{
    (void)userdata;
    fprintf(stderr, "%s\n", msg);
}

static void window_callback(GLWTWindow *window, const GLWTWindowEvent *event, void *userdata)
{
    (void)userdata;

    switch(event->type)
    {
        case GLWT_WINDOW_CLOSE:
            printf("Window closed\n");
            break;
        case GLWT_WINDOW_EXPOSE:
            printf("Window exposed\n");
            {
                glwtMakeCurrent(window);
                glwtSwapInterval(window, 1);

                glxwInit();

                glClearColor(0.2f, 0.4f, 0.7f, 1.0f);
                glClear(GL_COLOR_BUFFER_BIT);
                glwtSwapBuffers(window);

                glwtMakeCurrent(NULL);
            }
            break;
        case GLWT_WINDOW_RESIZE:
            printf("Window resized  width: %d  height: %d\n", event->resize.width, event->resize.height);
            break;
        case GLWT_WINDOW_SHOW:
        case GLWT_WINDOW_HIDE:
            printf("Window %s\n", (event->type == GLWT_WINDOW_SHOW) ? "show" : "hide");
            break;
        case GLWT_WINDOW_FOCUS_IN:
        case GLWT_WINDOW_FOCUS_OUT:
            printf("Window focus %s\n", (event->type == GLWT_WINDOW_FOCUS_IN) ? "in" : "out");
            break;
        case GLWT_WINDOW_KEY_UP:
        case GLWT_WINDOW_KEY_DOWN:
            printf("Key %s  keysym: 0x%x  scancode: %d  mod: %X\n",
                (event->type == GLWT_WINDOW_KEY_DOWN) ? "down" : "up",
                event->key.keysym, event->key.scancode, event->key.mod);
            break;
        case GLWT_WINDOW_BUTTON_UP:
        case GLWT_WINDOW_BUTTON_DOWN:
            printf("Button %s  x: %d  y: %d  button: %d  mod: %X\n",
                (event->type == GLWT_WINDOW_BUTTON_DOWN) ? "down" : "up",
                event->button.x, event->button.y, event->button.button, event->button.mod);
            break;
        case GLWT_WINDOW_MOUSE_MOTION:
            printf("Motion  x: %d  y: %d  buttons: %X\n",
                event->motion.x, event->motion.y, event->motion.buttons);
            break;
        case GLWT_WINDOW_MOUSE_ENTER:
        case GLWT_WINDOW_MOUSE_LEAVE:
            printf("Mouse %s\n", (event->type == GLWT_WINDOW_MOUSE_ENTER) ? "enter" : "leave");
            break;
        case GLWT_WINDOW_CHARACTER_INPUT:
            printf("Character input 0x%x (%c)\n",
                event->character.unicode,
                (event->character.unicode < 128 && isprint(event->character.unicode)) ?
                    event->character.unicode : ' ');
            if(event->character.unicode >= 128 || isprint(event->character.unicode))
            {
                int bytes = 0;
                char buf[5];

                bytes = encode_utf8(event->character.unicode, (unsigned char*)buf);
                buf[bytes] = 0;

                glwtWindowSetTitle(window, buf);
            }

            break;
        default:
            break;
    }
}

int main(int argc, char *argv[])
{
    int err = -1;
    GLWTWindow *window = 0;
    GLWTConfig glwt_config = {
        0, 0, 0, 0,
        0, 0,
        0, 0,
#ifdef GLWT_TESTS_GLES
        GLWT_API_OPENGL_ES | GLWT_PROFILE_DEBUG,
        2, 0,
#else
        GLWT_API_OPENGL | GLWT_PROFILE_DEBUG,
        0, 0,
#endif
    };

    (void)argc; (void)argv;

    if(glwtInit(&glwt_config, error_callback, NULL) != 0)
        goto error;

    if(!(window = glwtWindowCreate("", 400, 300, NULL, window_callback, NULL)))
        goto error;

    glwtWindowSetTitle(window, "GLWT Events test");
    glwtWindowShow(window, 1);

    while(!glwtWindowClosed(window))
    {
        if(glwtEventHandle(1) != 0)
            goto error;
    }

    err = 0;
error:
    glwtWindowDestroy(window);
    glwtQuit();
    return err;
}
