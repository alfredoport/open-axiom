/*
  Copyright (C) 1991-2002, The Numerical ALgorithms Group Ltd.
  All rights reserved.
  Copyright (C) 2007-2008, Gabriel Dos Reis.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      - Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

      - Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in
        the documentation and/or other materials provided with the
        distribution.

      - Neither the name of The Numerical ALgorithms Group Ltd. nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* menu of display used for testing out Gdraw functions in this directory */
#include "Gdraws0.h"
#include "../include/G.h"

extern GC gc;

void
Gdraws_draw_menu(Window menu, char *str, int width, int height)
{
   const char* str1 = "y e s";
   const char* str2 = "n o";
   int x0=0, y0=0;

   XDrawString(dsply, menu, gc, 30, height/4+3, str, strlen(str));

   XFillArc(dsply, menu, gc, 35, height/3+5, width/2-50, height/3*2-10,
            0*64, 360*64);

   XFillArc(dsply, menu, gc, width/2+5, height/3+5, width/2-50, height/3*2-10,
            0*64, 360*64);

   XSetForeground(dsply, gc, WhitePixel(dsply, scrn));
   XDrawString(dsply, menu, gc, width/4-5, height/3*2+3, str1, strlen(str1));
   XDrawString(dsply, menu, gc, width/4*3-28,height/3*2+3, str2, strlen(str2));
   XSetForeground(dsply, gc, BlackPixel(dsply, scrn));

   XFlush(dsply);
}
