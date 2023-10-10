% This file includes some macros from metafun. meatfun is released under
% a copyleft (GPL) license.
% See https://wiki.contextgarden.net/MetaFun_-_MetaPost_in_ConTeXt for more
% information.


% This is the original file header:

% %D \module
% %D   [       file=mp-tool.mpiv,
% %D        version=1998.02.15,
% %D          title=\CONTEXT\ \METAPOST\ graphics,
% %D       subtitle=auxiliary macros,
% %D         author=Hans Hagen,
% %D           date=\currentdate,
% %D      copyright={PRAGMA ADE \& \CONTEXT\ Development Team}]
% %C
% %C This module is part of the \CONTEXT\ macro||package and is
% %C therefore copyrighted by \PRAGMA. See mreadme.pdf for
% %C details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%        Shifting and scaling
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


def xshifted expr dx = shifted(dx,0) enddef ;
def yshifted expr dy = shifted(0,dy) enddef ;

primarydef p xyscaled q = % secundarydef does not work out well
    begingroup
    save qq ; pair qq ;
    qq = paired(q) ;
    p
        if xpart qq <> 0 : xscaled (xpart qq) fi
        if ypart qq <> 0 : yscaled (ypart qq) fi
    endgroup
enddef ;


vardef paired primary d =
    if pair d : d else : (d,d) fi
enddef ;

vardef tripled primary d =
    if color d : d else : (d,d,d) fi
enddef ;


def drawdot expr p =
    if pair p :
        addto currentpicture doublepath p
            withpen currentpen _op_
    elseif path p :
        draw image (
            for i=0 upto length p :
                addto currentpicture doublepath point i of p
                    withpen currentpen _op_ ;
            endfor ;
        )
    elseif picture p :
        draw image (
            save pp ; path pp ;
            for i within p :
                if stroked i or filled i :
                    pp := pathpart i ;
                    for j=0 upto length pp :
                        addto currentpicture doublepath point j of pp
                            withpen currentpen _op_ ;
                    endfor ;
                fi ;
            endfor ;
        )
    fi
enddef ;

primarydef p randomized s = (
    if path p :
        for i=0 upto length(p)-1 :
            ((point       i    of p) randomshifted s) .. controls
            ((postcontrol i    of p) randomshifted s) and
            ((precontrol (i+1) of p) randomshifted s) ..
        endfor
        if cycle p :
            cycle
        else :
            ((point length(p) of p) randomshifted s)
        fi
    elseif pair p :
        p randomshifted s
    elseif cmykcolor p :
        if color s :
           ((uniformdeviate cyanpart    s) * cyanpart    p,
            (uniformdeviate magentapart s) * magentapart p,
            (uniformdeviate yellowpart  s) * yellowpart  p,
            (uniformdeviate blackpart   s) * blackpart   p)
        elseif pair s :
            ((xpart s + (uniformdeviate (ypart s - xpart s))) * p)
        else :
            ((uniformdeviate s) * p)
        fi
    elseif rgbcolor p :
        if color s :
           ((uniformdeviate redpart   s) * redpart   p,
            (uniformdeviate greenpart s) * greenpart p,
            (uniformdeviate bluepart  s) * bluepart  p)
        elseif pair s :
           ((xpart s + (uniformdeviate (ypart s - xpart s))) * p)
        else :
           ((uniformdeviate s) * p)
        fi
    elseif color p :
        if color s :
            ((uniformdeviate greypart s) * greypart p)
        elseif pair s :
            ((xpart s + (uniformdeviate (ypart s - xpart s))) * p)
        else :
            ((uniformdeviate s) * p)
        fi
    else :
        p + uniformdeviate s
    fi
)
enddef ;

primarydef p randomshifted s =
    begingroup ;
    save ss ; pair ss ;
    ss := paired(s) ;
    p shifted (-.5xpart ss + uniformdeviate xpart ss,-.5ypart ss + uniformdeviate ypart ss)
    endgroup
enddef ;

primarydef p superellipsed s =
    superellipse (
        .5[lrcorner p,urcorner p],
        .5[urcorner p,ulcorner p],
        .5[ulcorner p,llcorner p],
        .5[llcorner p,lrcorner p],
        s
    )
enddef ;

vardef roundedsquare (expr width, height, offset) =
    (offset,0)            -- (width-offset,0)      {right} ..
    (width,offset)        -- (width,height-offset) {up}    ..
    (width-offset,height) -- (offset,height)       {left}  ..
    (0,height-offset)     -- (0,offset)            {down}  .. cycle
enddef ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%        Transparency
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vardef transparency_alternative_to_number(expr name) =
    if string name :
        if expandafter known scantokens(name & "transparent") :
            scantokens(name & "transparent")
        else :
            0
        fi
    elseif name < 17 :
        name
    else :
        0
    fi
enddef ;


def withtransparency(expr a, t) =
    withprescript "tr_alternative="  & decimal transparency_alternative_to_number(a)
    withprescript "tr_transparency=" & decimal t
enddef ;


def withopacity expr t =
    if pair t :
        withprescript "tr_alternative="  & decimal transparency_alternative_to_number(xpart t)
        withprescript "tr_transparency=" & decimal ypart t
    else :
        mfun_with_opacity (transparency_alternative_to_number(t))
    fi
enddef ;

def mfun_with_opacity (expr a) expr t =
    withprescript "tr_alternative="  & decimal a
    withprescript "tr_transparency=" & decimal t
enddef ;


primarydef n withalpha t =
    n withtransparency(1,t)
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%        Text
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


string defaultfontfamily, defaultfontstyle ;

defaultfontfamily := "text";
defaultfontstyle  := "regular";


def sptext(expr t, fnt, style) =
    runscript("sptext{"& fnt & ":" & style & ":" & t &"}")
enddef;


def txt(expr t) =
    runscript("sptext{"& defaultfontfamily & ":" & defaultfontstyle & ":" & t &"}")
enddef;


def spcolor(expr t) =
    runscript("spcolor{" & t & "}")
enddef;

