/+  *test, ha=heathcliff-api
|%
++  test-markdown-api
  =/  fields=(map @t json)
    (malt ~[['op' s+'markdown'] ['text' s+'# Heading']])
  =/  answer  (dispatch:ha *bowl:gall fields ~ ~)
  ?:  ?=(%| -.answer)  (expect !>(|))
  ?>  ?=(%o -.json.p.answer)
  =/  got=(unit json)  (~(get by p.json.p.answer) 'html')
  ;:  weld
    (expect !>(=(~ cards.p.answer)))
    (expect-eq !>(`s+'<div><h1>Heading</h1></div>') !>(got))
  ==
::
++  test-markdown-requires-text
  =/  fields=(map @t json)  (malt ~[['op' s+'markdown']])
  =/  answer  (dispatch:ha *bowl:gall fields ~ ~)
  ?.  ?=(%| -.answer)  (expect !>(|))
  (expect-eq !>(400) !>(status.p.answer))
::
++  test-markdown-refuses-large-source
  =/  text=@t  (rap 3 (reap 65.537 'x'))
  =/  fields=(map @t json)
    (malt ~[['op' s+'markdown'] ['text' s+text]])
  =/  answer  (dispatch:ha *bowl:gall fields ~ ~)
  ?.  ?=(%| -.answer)  (expect !>(|))
  (expect-eq !>(413) !>(status.p.answer))
--
