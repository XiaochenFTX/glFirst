//版本号必须显式地给出
#version 410

in vec4 inPos;

void main()
{
    gl_Position = inPos;
}