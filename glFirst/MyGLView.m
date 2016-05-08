//
//  MyGLView.m
//  glFirst
//
//  Created by 王晓辰 on 16/1/31.
//  Copyright © 2016年 ftxtool. All rights reserved.
//

#import "MyGLView.h"

#include <OpenGL/gl3.h>
#include <OpenGL/gl3ext.h>

#include <stdio.h>

GLuint program, vbo, vao;

@implementation MyGLView

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // create shader program
    program = glCreateProgram();
    
    // bind attribute locations
    // this needs to be done prior to linking
    glBindAttribLocation(program, 0, "inPos");
    
    // create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // attach vertex shader to program
    glAttachShader(program, vertShader);
    
    // attach fragment shader to program
    glAttachShader(program, fragShader);
    
    //glBindFragDataLocationEXT(program, 0, "myOutput");
    
    // link program
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        return FALSE;
    }
    
    // release vertex and fragment shaders
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    
    [[self openGLContext] makeCurrentContext];
    
    self = [super initWithCoder:coder];
    
    return self;
}

+ (NSOpenGLPixelFormat*)defaultPixelFormat {
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,    // 可选地，可以使用双缓冲
        NSOpenGLPFAOpenGLProfile,   // Must specify the 3.2 Core Profile to use OpenGL 3.2
        NSOpenGLProfileVersion4_1Core,
        0
    };

    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
}

- (void)prepareOpenGL {
    GLfloat squareVertices[] = {
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
    };
    
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertices), squareVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, 0, 0, (const GLvoid*)0);
    
    // Load shaders and build the program
    if(![self loadShaders])
        return;
    
    // Use shader program
    glUseProgram(program);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
}

//- (void)reshape
//{
//    //Get view dimensions
//    NSRect baseRect = [self convertRectToBase:[self bounds]];
//    int w, h;
//    w = baseRect.size.width;
//    h = baseRect.size.height;
//    
//    //Add your OpenGL resize code here
//    glViewport(0, 0, (GLsizei)450, (GLsizei)300);
//}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glFlush();
    
    printf("[drawRect] x=%f,\ty=%f,\tw=%f,\th=%f\n", dirtyRect.origin.x, dirtyRect.origin.y, dirtyRect.size.width, dirtyRect.size.height);
    
    [[self openGLContext] flushBuffer];
}

// Put our timer in -awakeFromNib, so it can start up right from the beginning
-(void)awakeFromNib
{
    NSTimer* renderTimer = [NSTimer timerWithTimeInterval:0.016   //a 1ms time interval
                                          target:self
                                        selector:@selector(timerFired:)
                                        userInfo:nil
                                         repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                 forMode:NSDefaultRunLoopMode];
//    [[NSRunLoop currentRunLoop] addTimer:renderTimer
//                                 forMode:NSEventTrackingRunLoopMode]; //Ensure timer fires during resize
}

// Timer callback method
- (void)timerFired:(id)sender
{
    // It is good practice in a Cocoa application to allow the system to send the -drawRect:
    // message when it needs to draw, and not to invoke it directly from the timer.
    // All we do here is tell the display it needs a refresh
    [self setNeedsDisplay:YES];
}

@end
