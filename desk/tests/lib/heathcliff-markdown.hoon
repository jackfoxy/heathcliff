/+  *test, hm=heathcliff-markdown
|%
++  test-gfm-rendering
  =/  got=(unit @t)
    %-  render:hm
    '''
    # Heading

    **bold** and ~~gone~~

    - [x] done

    | A | B |
    | --- | --- |
    | 1 | 2 |
    '''
  ?~  got  (expect !>(|))
  =/  parts=(list tape)
    :~  "<h1>"  "<strong>bold</strong>"  "<del>gone</del>"
        "<table>"  "disabled="
    ==
  %-  zing
  %+  turn  parts
  |=(part=tape (expect !>(?=(^ (find part (trip u.got))))))
::
++  test-restrict-html
  =/  input=manx
    ;div
      ;script: alert(1)
      ;img(src "javascript:alert(1)", onerror "alert(1)");
      ;a(href "https://example.com", onclick "alert(1)"): link
      ;input(type "text", value "editable");
    ==
  =/  got=tape  (en-xml:html (clean:hm input))
  ;:  weld
    (expect !>(=(~ (find "<script" got))))
    (expect !>(=(~ (find "javascript:" got))))
    (expect !>(=(~ (find "onerror" got))))
    (expect !>(=(~ (find "onclick" got))))
    (expect !>(?=(^ (find "https://example.com" got))))
    (expect !>(?=(^ (find "disabled=" got))))
  ==
::
++  test-url-policy
  ;:  weld
    (expect !>((safe-url:hm "https://example.com/a")))
    (expect !>((safe-url:hm "../image.png")))
    (expect !>(!(safe-url:hm "javascript:alert(1)")))
    (expect !>(!(safe-url:hm "data:text/html,hello")))
    (expect !>(!(safe-url:hm "java\0ascript:alert(1)")))
  ==
::
++  test-preview-size-limit
  (expect !>(=(~ (render:hm (rap 3 (reap +(limit:hm) 'x'))))))
--
