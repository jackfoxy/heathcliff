::  Markdown previews: parse source, then restrict the rendered Sail tree.
::
/+  md=markdown
|%
++  limit  65.536
::
++  render
  |=  text=@t
  ^-  (unit @t)
  ?:  (gth (met 3 text) limit)  ~
  =/  parsed  (de:md text)
  ?~  parsed  ~
  `(crip (en-xml:html (clean (sail-en:md u.parsed))))
::
++  clean
  ::  Embedded HTML shares the same allowlist as generated Markdown.
  |=  node=manx
  ^-  manx
  ?:  =(%$ n.g.node)  node
  ?.  ?=(@ n.g.node)  ;span;
  ?.  (lien tags |=(tag=@tas =(tag n.g.node)))  ;span;
  ?:  =(%input n.g.node)
    =/  checked=?  (lien a.g.node |=([n=mane v=tape] =(%checked n)))
    ?:  checked
      ;input(type "checkbox", disabled "disabled", checked "checked");
    ;input(type "checkbox", disabled "disabled");
  =/  attrs=mart
    %+  skim  a.g.node
    |=  attr=[n=mane v=tape]
    ?+  n.attr  |
      ?(%alt %title %class %align %start %type %checked %disabled)  &
      ?(%href %src)  (safe-url v.attr)
    ==
  [[n.g.node attrs] (turn c.node clean)]
::
++  tags
  ^-  (list @tas)
  :~  %div  %span  %p  %h1  %h2  %h3  %h4  %h5  %h6
      %em  %strong  %del  %strike  %s  %b  %i  %u
      %pre  %code  %blockquote  %ul  %ol  %li  %hr  %br
      %table  %thead  %tbody  %tr  %th  %td  %a  %img
      %input
  ==
::
++  safe-url
  |=  url=tape
  ^-  ?
  ?:  (lien url |=(c=@t |((lth c 33) =(c 127) =(c 92))))  |
  ?.  (lien url |=(c=@t =(c ':')))  &
  =/  prefixes=(list tape)  ~["https://" "http://" "mailto:"]
  %+  lien  prefixes
  |=(prefix=tape =(prefix (scag (lent prefix) url)))
--
