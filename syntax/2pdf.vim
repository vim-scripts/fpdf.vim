" Last Chage: 2008-08-13
" Options:
"   g:topdf_font          (default: "Courier")
"   g:topdf_font_size     (default: 10)
"   g:topdf_header_font   (default: g:topdf_font)
"   g:topdf_footer_font   (default: g:topdf_font)
"   g:topdf_header        (default: "")
"   g:topdf_footer        (default: "Page {n}/{nb}")
"     In this variable, {expr} is interpreted as eval(expr).  Following
"     variable can be used.
"     {n}     Current page number
"     {nb}    Number of pages

let s:fpdf = fpdf#import()
let s:topdf = copy(s:fpdf)

let s:topdf.config = {}
let s:topdf.config['font'] = get(g:, 'topdf_font', 'Courier')
let s:topdf.config['font_size'] = get(g:, 'topdf_font_size', 10)
let s:topdf.config['line_height'] = get(g:, 'topdf_line_height', s:topdf.config['font_size'] / 2.0)
let s:topdf.config['header_font'] = get(g:, 'topdf_header_font', s:topdf.config['font'])
let s:topdf.config['footer_font'] = get(g:, 'topdf_footer_font', s:topdf.config['font'])
let s:topdf.config['header'] = get(g:, 'topdf_header', '')
let s:topdf.config['footer'] = get(g:, 'topdf_footer', 'Page {n}/{nb}')

function! s:topdf.Header()
  let header = self.config['header']
  if header != ''
    let header = substitute(header, '{\(.\{-}\)}', '\=eval(submatch(1))', 'g')
    call self.setstyle('body')
    call self.SetFont(self.config['header_font'], 'B', self.config['font_size'])
    call self.Cell(0, self.config['line_height'], header, 0, 0, 'C')
    call self.Ln()
  endif
endfunction

function! s:topdf.Footer()
  let footer = self.config['footer']
  if footer != ''
    let n = self.PageNo()
    let nb = '{nb}'
    let footer = substitute(footer, '{\(.\{-}\)}', '\=eval(submatch(1))', 'g')
    call self.SetY(-15)
    call self.setstyle('body')
    call self.SetFont(self.config['footer_font'], 'I', self.config['font_size'])
    call self.Cell(0, self.config['line_height'], footer, 0, 0, 'C')
  endif
endfunction

function! s:topdf.Write(...)
  let self.cMargin = 0
  call call(s:fpdf.Write, a:000, self)
endfunction

function! s:topdf.unescape_entity(str)
  let replace = {'amp':'&', 'lt':'<', 'gt':'>', 'quot':'"', 'nbsp':' '}
  return substitute(a:str, '&\('.join(keys(replace),'\|').'\);', '\=replace[submatch(1)]', 'g')
endfunction

function! s:topdf.hex2rgb(hexcolor)
  let _ = matchlist(a:hexcolor, '#\?\(\x\{2}\)\(\x\{2}\)\(\x\{2}\)')
  return map(_[1:3], 'str2nr(v:val, 16)')
endfunction

function! s:topdf.setstyle(name)
  let s = self.style[a:name]
  if !has_key(s, 'color')
    let s['color'] = get(self.style['body'], 'color', '#000000')
  endif
  if !has_key(s, 'background-color')
    let s['background-color'] = get(self.style['body'], 'background-color', '#FFFFFF')
  endif
  if get(s, 'font-weight') == 'bold'
    call self.SetFont(self.config['font'], 'B', self.config['font_size'])
  else
    call self.SetFont(self.config['font'], '', self.config['font_size'])
  endif
  let [r, g, b] = self.hex2rgb(s['color'])
  call self.SetTextColor(r, g, b)
  let [r, g, b] = self.hex2rgb(s['background-color'])
  call self.SetFillColor(r, g, b)
endfunction

function! s:topdf() abort
  call s:tohtml()

  let style = {}

  let lnum = 1
  while getline(lnum) !~ '<style'
    let lnum += 1
  endwhile
  while getline(lnum) !~ '</style'
    let _ = matchlist(getline(lnum), '^\.\?\(\w\+\)\s*{\(.*\)}$')
    if !empty(_)
      let name = _[1]
      let style[name] = {}
      let m = s:lib.Matcher.new(_[2], '\([A-Za-z-]\+\):\s*\([0-9A-Za-z#]\+\);')
      while m.find()
        let style[name][m[1]] = m[2]
      endwhile
    endif
    let lnum += 1
  endwhile

  while getline(lnum) != '<body>'
    let lnum += 1
  endwhile
  let lnum += 1

  let topdf = s:topdf.new()
  let topdf.style = style

  call topdf.AliasNbPages()
  call topdf.AddPage()

  while getline(lnum) != '</body>'
    let line = matchstr(getline(lnum), '.*\ze<br>')
    let m = s:lib.Matcher.new(line, '<span class="\(\w\+\)">\([^<]\+\)</span>')
    while m.find()
      if m.head() != ''
        call topdf.setstyle('body')
        call topdf.Write(topdf.config['line_height'], topdf.unescape_entity(m.head()), '')
      endif
      let fill = has_key(style[m[1]], 'background-color')
      call topdf.setstyle(m[1])
      call topdf.Write(topdf.config['line_height'], topdf.unescape_entity(m[2]), '', fill)
    endwhile
    if m.tail() != ''
      call topdf.setstyle('body')
      call topdf.Write(topdf.config['line_height'], topdf.unescape_entity(m.tail()), '')
    endif
    call topdf.Ln()
    let lnum += 1
  endwhile

  bwipeout!
  new
  put =topdf.Output()
endfunction

function! s:tohtml()
  let save = {}
  if exists('g:html_use_css')
    let save['g:html_use_css'] = g:html_use_css
  endif
  if exists('g:html_no_pre')
    let save['g:html_no_pre'] = g:html_no_pre
  endif
  if exists('g:use_xhtml')
    let save['g:use_xhtml'] = g:use_xhtml
  endif

  let g:html_use_css = 1
  let g:html_no_pre = 1
  unlet! g:use_xhtml

  runtime syntax/2html.vim

  for [k,v] in items(save)
    let {k} = v
  endfor
endfunction

let s:lib = {}

let s:lib.Matcher = {}

function s:lib.Matcher.new(expr, pat)
  let res = copy(self)
  let res.expr = a:expr
  let res.pat = a:pat
  let res.submatch = []
  let res.last = 0
  let res.start = 0
  return res
endfunction

function s:lib.Matcher.find()
  if self.start == -1
    return 0
  endif
  if self.submatch != []
    let self.last = matchend(self.expr, self.pat, self.start)
  endif
  let self.start = match(self.expr, self.pat, self.last)
  if self.start == -1
    return 0
  endif
  let self.submatch = matchlist(self.expr, self.pat, self.start)
  for i in range(len(self.submatch))
    let self[i] = self.submatch[i]
  endfor
  return 1
endfunction

function s:lib.Matcher.head()
  return strpart(self.expr, self.last, self.start - self.last)
endfunction

function s:lib.Matcher.tail()
  if self.start != -1
    return strpart(self.expr, matchend(self.expr, self.pat, self.start))
  endif
  return strpart(self.expr, self.last)
endfunction

call s:topdf()
