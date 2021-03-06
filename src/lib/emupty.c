/*
    Copyright (c) 1991-2002, The Numerical ALgorithms Group Ltd.
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

#include "openaxiom-c-macros.h"

/*
  Here is some code taken from Nick Simicich. It takes an escape sequence
  from the child, and if I am actually talking to an HFT device, it
  translates that escape sequence into an ioctl call.
  */


#if 0

#include "edible.h"
#include "sys/devinfo.h"
#include <sys/ioctl.h>

typedef union {
   struct hfintro *hf;
   struct hfctlreq *re;
   char *c;
} Argument;

emuhft(Argument arg, int tty, int ptc, int len)
{
    /* What does it do? */
    /* 1.  There are a number of ioctl's associated with the HFT terminal. */
    /* 2.  When an HFT terminal is being emulated over a PTY, the */
    /* IOCTL cannot be executed directly on the server end of the PTY. */
    /* 3.  A system defined structure is set up such that the program */
    /* at the end of the PTY can issue the ioctl as an escape */
    /* sequence and get its response as an escape sequence. */
    /* 4.  This is badly broken, even stupid.  If the protocol is */
    /* defined, and everyone is supposed to use it, then the HFT */
    /* should react directly to it.  But No.... */
    /* 5.  Furthermore, our terminal itself might be a pty.  In that */
    /* case, we have to transmit the data just as we got it to the */
    /* other PTY, instead of executing the IOCTL. */

    static union {
        struct hfintro hfi;
        struct hfctlack ackn;
        char charvector[1024];  /* Spacer to make sure that response can be
                                 * moved here */
    }   aa;

    extern int errno;

#ifdef DEBUG
    dstream(arg.c, stderr, NULL, "From emuhft (input)");
#endif

    if (len > 1000) {
        fprintf(stderr, "Unreasonable value for len %d\n", len);
        return -1;
    }

    if (ioctl(tty, IOCTYPE, 0) != (DD_PSEU << 8)) {     /* is it a pty ?      */
        switch (arg.re->hf_request) {
          case HFQUERY:{
                struct hfquery hfqur;
                int i;

                hfqur.hf_resplen = iiret(arg.re->hf_rsp_len);
                if (hfqur.hf_resplen > 0) {
                    hfqur.hf_resp = aa.charvector + sizeof aa.ackn;
                    if (hfqur.hf_resplen > (sizeof aa.charvector - sizeof
                                            aa.ackn)) {
                        errno = ENOMEM;
                        perror("Can't store HFQUERY response");
                        return -1;
                    }
                }
                else
                    hfqur.hf_resp = NULL;

                hfqur.hf_cmd = arg.c + 3 + ciret(arg.hf->hf_len);
                hfqur.hf_cmdlen = iiret(arg.re->hf_arg_len);
                i = ioctl(tty, HFQUERY, &hfqur);        /* The meat of the
                                                         * matter */
                aa.hfi.hf_esc = HFINTROESC;
                aa.hfi.hf_lbr = HFINTROLBR;
                aa.hfi.hf_ex = HFINTROEX;
                icmove(sizeof aa.ackn - 3, aa.hfi.hf_len);
                aa.hfi.hf_typehi = HFCTLACKCH;
                aa.hfi.hf_typelo = HFCTLACKCL;
                if (i == -1)
                    aa.ackn.hf_retcode = errno;
                else
                    aa.ackn.hf_retcode = 0;
                aa.ackn.hf_sublen = arg.re->hf_sublen;
                aa.ackn.hf_subtype = arg.re->hf_subtype;
                aa.ackn.hf_request = iiret(arg.re->hf_request);
                aa.ackn.hf_arg_len = hfqur.hf_resplen;
                if (-1 == write(ptc, aa.charvector, (sizeof aa.ackn) +
                                hfqur.hf_resplen)) {
                    perror("write of HFQUERY acknowledgement failed");
                    return (-1);
                }
#ifdef DEBUG
                dstream(aa.charvector, stderr, NULL, "From emuhft (hfquery ack)");
#endif
                break;
            }
          case HFSKBD:{
                struct hfbuf hfkey;
                int i;

                hfkey.hf_bufp = arg.c + 3 + ciret(arg.hf->hf_len);
                hfkey.hf_buflen = iiret(arg.re->hf_arg_len);
                i = ioctl(tty, HFSKBD, &hfkey); /* The meat of the matter */
                aa.hfi.hf_esc = HFINTROESC;
                aa.hfi.hf_lbr = HFINTROLBR;
                aa.hfi.hf_ex = HFINTROEX;
                icmove(sizeof aa.ackn - 3, aa.hfi.hf_len);
                aa.hfi.hf_typehi = HFCTLACKCH;
                aa.hfi.hf_typelo = HFCTLACKCL;
                if (i == -1)
                    aa.ackn.hf_retcode = errno;
                else
                    aa.ackn.hf_retcode = 0;
                aa.ackn.hf_sublen = arg.re->hf_sublen;
                aa.ackn.hf_subtype = arg.re->hf_subtype;
                aa.ackn.hf_request = iiret(arg.re->hf_request);
                aa.ackn.hf_arg_len = 0;
                if (-1 == write(ptc, aa.charvector, sizeof aa.ackn)) {
                    perror("write of HFSKEY acknowledgement failed");
                    return (-1);
                }
#ifdef DEBUG
                dstream(aa.charvector, stderr, NULL, "From emuhft (HFSKEY ack)");
#endif
                break;
            }
          default:{
                aa.hfi.hf_esc = HFINTROESC;
                aa.hfi.hf_lbr = HFINTROLBR;
                aa.hfi.hf_ex = HFINTROEX;
                icmove(sizeof aa.ackn - 3, aa.hfi.hf_len);
                aa.hfi.hf_typehi = HFCTLACKCH;
                aa.hfi.hf_typelo = HFCTLACKCL;
                aa.ackn.hf_retcode = EINVAL;
                aa.ackn.hf_sublen = arg.re->hf_sublen;
                aa.ackn.hf_subtype = arg.re->hf_subtype;
                aa.ackn.hf_request = iiret(arg.re->hf_request);
                aa.ackn.hf_arg_len = 0;
                if (-1 == write(ptc, aa.charvector, sizeof aa.ackn)) {
                    perror("write of default acknowledgement failed");
                    return (-1);
                }
#ifdef DEBUG
                dstream(aa.charvector, stderr, NULL, "From emuhft (default ack)");
#endif

                break;
            }
        }
    }
    else {
        /* Well, if we get here, we are a pseudo-device ourselves.  So */
        /* we will just send on the request that we got.  we are in a */
        /* unique situation.  We believe that both ptc and tty are as */
        /* transparent as we can get them, so we don't have to worry. */
        /* We will just write the request to the tty,  which we */
        /* believe is a pty, and sooner or later, the ack will come */
        /* back. */
        if (-1 == write(tty, arg.c, len)) {
            perror("write of control sequence to pty failed");
            fprintf(stderr, "tty = %d, len = %d\n", tty, len);
            return (-1);
        }
#ifdef DEBUG
        dstream(arg.c, stderr, NULL, "From emuhft (on pty transfer)");
        fprintf(stderr, "tty = %d, len = %d\r\n", tty, len);
        fflush(stderr);
#endif

    }
    return 0;
}



#endif

static int _ThatsAll_(int x) 
{
return x;
}
