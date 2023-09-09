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

primarydef n withalpha t =
    n withprescript "alpha=" & decimal(t) withpostscript "endalpha";
enddef;
