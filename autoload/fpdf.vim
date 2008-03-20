"*******************************************************************************
" Software: FPDF                                                               *
" Version:  1.53                                                               *
" Date:     2004-12-31                                                         *
" Author:   Olivier PLATHEY                                                    *
" License:  Freeware                                                           *
"                                                                              *
" You may use, modify and redistribute this software as you wish.              *
"******************************************************************************/
" 2008-03-20: ported to vim by Yukihiro Nakadaira <yukihiri.nakadaira@gmail.com>
"
" TODO: embed font and image (use xxd and ASCIIHexDecode?)

function fpdf#import()
  return s:fpdf
endfunction

let s:float = float#import()

let s:__file__ = expand("<sfile>:p")

let s:FPDF_VERSION = '1.53'
let s:FPDF_VIM_VERSION = '0.1'

let s:false = 0
let s:true = 1

function! s:sprintf(fmt, ...)
  let fmt = substitute(a:fmt, '%[^%]\{-}f', '%s', 'g')
  let args = [fmt]
  for v in a:000
    if s:float.is_float(v)
      " TODO: fmt
      call add(args, v.tostr())
    else
      call add(args, v)
    endif
    unlet v
  endfor
  return call('printf', args)
endfunction

function! s:mb_strlen(s)
  return len(substitute(a:s, '.', '.', 'g'))
endfunction

function! s:mb_strwidth(s)
  let n = 0
  for c in split(a:s, '\zs')
    let n += s:mb_charwidth(c)
  endfor
  return n
endfunction

function! s:mb_charwidth(c)
  return (a:c =~ '^.\%2v') ? 1 : 2
endfunction

function! s:mb_substr(s, offset, ...)
  let len = get(a:000, 0, -1)
  let start = byteidx(a:s, a:offset)
  if len == -1
    return strpart(a:s, start)
  else
    let end = byteidx(a:s, a:offset + len)
    return strpart(a:s, start, end - start)
  endif
endfunction

function! s:include(file)
  so `=a:file`
endfunction

function! s:is_string(v)
  return (type(a:v) == type(''))
endfunction

function! s:is_bool(v)
 return (type(a:v) == type(0) && (a:v == 0 || a:v == 1))
endfunction

function! s:is_array(v)
  return (type(a:v) == type([]))
endfunction

function! s:dirname(p)
  return fnamemodify(a:p, ':h')
endfunction

function! s:gzcompress(data)
  throw 'gzcompress: not implemented'
endfunction

function! s:fread(path)
  throw 'fread: not impremented'
endfunction

function! s:get_magic_quotes_runtime()
  return 0
endfunction

function! s:set_magic_quotes_runtime(mqr)
  " void
endfunction

function! s:equal(a, b)
  return (type(a:a) == type(a:b) && a:a == a:b)
endfunction

function! s:substr_count(txt, sub)
  let n = 0
  let i = match(a:txt, a:sub, 0)
  while i != -1
    let n += 1
    let i = match(a:txt, a:sub, matchend(a:txt, a:sub, i))
  endwhile
  return n
endfunction

let s:fpdf = {}

"var $page;               "current page number
"var $n;                  "current object number
"var $offsets;            "array of object offsets
"var $buffer;             "buffer holding in-memory PDF
"var $pages;              "array containing pages
"var $state;              "current document state
"var $compress;           "compression flag
"var $DefOrientation;     "default orientation
"var $CurOrientation;     "current orientation
"var $OrientationChanges; "array indicating orientation changes
"var $k;                  "scale factor (number of points in user unit)
"var $fwPt,$fhPt;         "dimensions of page format in points
"var $fw,$fh;             "dimensions of page format in user unit
"var $wPt,$hPt;           "current dimensions of page in points
"var $w,$h;               "current dimensions of page in user unit
"var $lMargin;            "left margin
"var $tMargin;            "top margin
"var $rMargin;            "right margin
"var $bMargin;            "page break margin
"var $cMargin;            "cell margin
"var $x,$y;               "current position in user unit for cell positioning
"var $lasth;              "height of last cell printed
"var $LineWidth;          "line width in user unit
"var $CoreFonts;          "array of standard font names
"var $fonts;              "array of used fonts
"var $FontFiles;          "array of font files
"var $diffs;              "array of encoding differences
"var $images;             "array of used images
"var $PageLinks;          "array of links in pages
"var $links;              "array of internal links
"var $FontFamily;         "current font family
"var $FontStyle;          "current font style
"var $underline;          "underlining flag
"var $CurrentFont;        "current font info
"var $FontSizePt;         "current font size in points
"var $FontSize;           "current font size in user unit
"var $DrawColor;          "commands for drawing color
"var $FillColor;          "commands for filling color
"var $TextColor;          "commands for text color
"var $ColorFlag;          "indicates whether fill and text colors are different
"var $ws;                 "word spacing
"var $AutoPageBreak;      "automatic page breaking
"var $PageBreakTrigger;   "threshold used to trigger page breaks
"var $InFooter;           "flag set when processing footer
"var $ZoomMode;           "zoom display mode
"var $LayoutMode;         "layout display mode
"var $title;              "title
"var $subject;            "subject
"var $author;             "author
"var $keywords;           "keywords
"var $creator;            "creator
"var $AliasNbPages;       "alias for total number of pages
"var $PDFVersion;         "PDF version number

"*******************************************************************************
"                                                                              *
"                               Public methods                                 *
"                                                                              *
"******************************************************************************/

function s:fpdf.new(...)
  let new = copy(self)
  call call(self.__construct, a:000, new)
  return new
endfunction

function s:fpdf.__construct(...)
  let orientation = get(a:000, 0, 'P')
  let unit = get(a:000, 1, 'mm')
  let format = get(a:000, 2, 'A4')
  "Initialization of properties
  let self.page = 0
  let self.n = 2
  let self.offsets = {}
  let self.buffer = ''
  let self.pages = {}
  let self.OrientationChanges = {}
  let self.state = 0
  let self.fonts = {}
  let self.FontFiles = {}
  let self.diffs = []
  let self.images = {}
  let self.PageLinks = {}
  let self.links = {}
  let self.InFooter = s:false
  let self.lasth = 0
  let self.FontFamily = ''
  let self.FontStyle = ''
  let self.FontSizePt = s:float.new(12)
  let self.underline = s:false
  let self.DrawColor = '0 G'
  let self.FillColor = '0 g'
  let self.TextColor = '0 g'
  let self.ColorFlag = s:false
  let self.ws = 0
  "Standard fonts
  let self.CoreFonts = {
        \ 'courier':'Courier','courierB':'Courier-Bold','courierI':'Courier-Oblique','courierBI':'Courier-BoldOblique',
        \ 'helvetica':'Helvetica','helveticaB':'Helvetica-Bold','helveticaI':'Helvetica-Oblique','helveticaBI':'Helvetica-BoldOblique',
        \ 'times':'Times-Roman','timesB':'Times-Bold','timesI':'Times-Italic','timesBI':'Times-BoldItalic',
        \ 'symbol':'Symbol','zapfdingbats':'ZapfDingbats'
        \ }
  "Scale factor
  if unit == 'pt'
    let self.k = s:float.new(1)
  elseif unit == 'mm'
    let self.k = s:float.div('72', '25.4')
  elseif unit == 'cm'
    let self.k = s:float.div('72', '2.54')
  elseif unit == 'in'
    let self.k = s:float.new(72)
  else
    throw 'Incorrect unit: ' . unit
  endif
  "Page format
  if s:is_string(format)
    if format ==? 'a3'
      unlet format
      let format = ['841.89','1190.55']
    elseif format ==? 'a4'
      unlet format
      let format = ['595.28','841.89']
    elseif format ==? 'a5'
      unlet format
      let format = ['420.94','595.28']
    elseif format ==? 'letter'
      unlet format
      let format = ['612','792']
    elseif format ==? 'legal'
      unlet format
      let format = ['612','1008']
    else
      throw 'Unknown page format: ' . format
    endif
    let self.fwPt = format[0]
    let self.fhPt = format[1]
  else
    let self.fwPt = s:float.mul(format[0], self.k)
    let self.fhPt = s:float.mul(format[1], self.k)
  endif
  let self.fw = s:float.div(self.fwPt, self.k)
  let self.fh = s:float.div(self.fwPt, self.k)
  "Page orientation
  let orientation = tolower(orientation)
  if orientation == 'p' || orientation == 'portrait'
    let self.DefOrientation = 'P'
    let self.wPt = self.fwPt
    let self.hPt = self.fhPt
  elseif orientation == 'l' || orientation == 'landscape'
    let self.DefOrientation = 'L'
    let self.wPt = self.fhPt
    let self.hPt = self.fwPt
  else
    throw 'Incorrect orientation: ' . orientation
  endif
  let self.CurOrientation = self.DefOrientation
  let self.w = s:float.div(self.wPt, self.k)
  let self.h = s:float.div(self.hPt, self.k)
  "Page margins (1 cm)
  let margin = s:float.div('28.35', self.k)
  call self.SetMargins(margin, margin)
  "Interior cell margin (1 mm)
  let self.cMargin = s:float.div(margin, '10')
  "Line width (0.2 mm)
  let self.LineWidth = s:float.div('.567', self.k)
  "Automatic page break
  call self.SetAutoPageBreak(s:true, s:float.mul('2', margin))
  "Full width display mode
  call self.SetDisplayMode('fullwidth')
  "Enable compression
  call self.SetCompression(s:false)
  "Set default PDF version number
  let self.PDFVersion = '1.3'

  let self.title = ''
  let self.subject = ''
  let self.author = ''
  let self.keywords = ''
  let self.creator = ''
endfunction

function s:fpdf.SetMargins(...)
  let left = s:float.new(get(a:000, 0))
  let top = s:float.new(get(a:000, 1))
  let right = s:float.new(get(a:000, 2, -1))
  "Set left, top and right margins
  let self.lMargin = left
  let self.tMargin = top
  if s:float.cmp(right, -1) == 0
    let right = left
  endif
  let self.rMargin = right
endfunction

function s:fpdf.SetLeftMargin(margin)
  let margin = s:float.new(a:margin)
  "Set left margin
  let self.lMargin = margin
  if self.page > 0 && s:float.cmp(self.x, margin) < 0
    let self.x = margin
  endif
endfunction

function s:fpdf.SetTopMargin(margin)
  "Set top margin
  let self.tMargin = s:float.new(a:margin)
endfunction

function s:fpdf.SetRightMargin(margin)
  "Set right margin
  let self.rMargin = s:float.new(s:margin)
endfunction

function s:fpdf.SetAutoPageBreak(...)
  let auto = get(a:000, 0)
  let margin = s:float.new(get(a:000, 1, 0))
  "Set auto page break mode and triggering margin
  let self.AutoPageBreak = auto
  let self.bMargin = margin
  let self.PageBreakTrigger = s:float.sub(self.h, margin)
endfunction

function s:fpdf.SetDisplayMode(...)
  let zoom = get(a:000, 0)
  let layout = get(a:000, 1, 'continuous')
  "Set display mode in viewer
  if zoom == 'fullpage' || zoom == 'fullwidth' || zoom == 'real' || zoom == 'default' || s:is_string(zoom)
    let self.ZoomMode = zoom
  else
    throw 'Incorrect zoom display mode: ' . zoom
  endif
  if layout == 'single' || layout == 'continuous' || layout == 'two' || layout == 'default'
    let self.LayoutMode = layout
  else
    throw 'Incorrect layout display mode: ' . layout
  endif
endfunction

function s:fpdf.SetCompression(compress)
  let self.compress = a:compress
endfunction

function s:fpdf.SetTitle(title)
  "Title of document
  let self.title = a:title
endfunction

function s:fpdf.SetSubject(subject)
  "Subject of document
  let self.subject = a:subject
endfunction

function s:fpdf.SetAuthor(author)
  "Author of document
  let self.author = a:author
endfunction

function s:fpdf.SetKeywords(keywords)
  "Keywords of document
  let self.keywords = a:keywords
endfunction

function s:fpdf.SetCreator(creator)
  "Creator of document
  let self.creator = a:creator
endfunction

function s:fpdf.AliasNbPages(...)
  let alias = get(a:000, 0, '{nb}')
  "Define an alias for total number of pages
  let self.vAliasNbPages = alias
endfunction

function s:fpdf.Open()
  "Begin document
  let self.state = 1
endfunction

function s:fpdf.Close()
  "Terminate document
  if self.state ==3
    return
  endif
  if self.page == 0
    call self.AddPage()
  endif
  "Page footer
  let self.InFooter = s:true
  call self.Footer()
  let self.InFooter = s:false
  "Close page
  call self._endpage()
  "Close document
  call self._enddoc()
endfunction

function s:fpdf.AddPage(...)
  let orientation = get(a:000, 0, '')
  "Start a new page
  if self.state == 0
    call self.Open()
  endif
  let family = self.FontFamily
  let style = self.FontStyle . (self.underline ? 'U' : '')
  let size = self.FontSizePt
  let lw = self.LineWidth
  let dc = self.DrawColor
  let fc = self.FillColor
  let tc = self.TextColor
  let cf = self.ColorFlag
  if self.page > 0
    "Page footer
    let self.InFooter = s:true
    call self.Footer()
    let self.InFooter = s:false
    "Close page
    call self._endpage()
  endif
  "Start new page
  call self._beginpage(orientation)
  "Set line cap style to square
  call self._out('2 J')
  "Set line width
  let self.LineWidth = lw
  call self._out(s:sprintf('%.2f w', s:float.mul(lw, self.k)))
  "Set font
  if family != ''
    call self.SetFont(family, style, size)
  endif
  "Set colors
  let self.DrawColor = dc
  if dc != '0 G'
    call self._out(dc)
  endif
  let self.FillColor = fc
  if fc != '0 g'
    call self._out(fc)
  endif
  let self.TextColor = tc
  let self.ColorFlag = cf
  "Page header
  call self.Header()
  "Restore line width
  if self.LineWidth != lw
    let self.LineWidth = lw
    call self._out(s:sprintf('%.2f w', s:float.mul(lw, self.k)))
  endif
  "Restore font
  if family != ''
    call self.SetFont(family, style, size)
  endif
  "Restore colors
  if self.DrawColor != dc
    let self.DrawColor = dc
    call self._out(dc)
  endif
  if self.FillColor != fc
    let self.FillColor = fc
    call self._out(fc)
  endif
  let self.TextColor = tc
  let self.ColorFlag = cf
endfunction

function s:fpdf.Header()
  "To be implemented in your own inherited class
endfunction

function s:fpdf.Footer()
  "To be implemented in your own inherited class
endfunction

function s:fpdf.PageNo()
  "Get current page number
  return self.page
endfunction

function s:fpdf.SetDrawColor(...)
  let r = s:float.new(get(a:000, 0))
  let g = s:float.new(get(a:000, 1, -1))
  let b = s:float.new(get(a:000, 2, -1))
  "Set color for all stroking operations
  if (s:float.cmp(r, 0) == 0 && s:float.cmp(g, 0) == 0 && s:float.cmp(b, 0) == 0) || s:float.cmp(g, -1) == 0
    let self.DrawColor = s:sprintf('%.3f G', s:float.div(r, 255))
  else
    let self.DrawColor = s:sprintf('%.3f %.3f %.3f RG', s:float.div(r, 255), s:float.div(g, 255), s:float.div(b, 255))
  endif
  if self.page > 0
    call self._out(self.DrawColor)
  endif
endfunction

function s:fpdf.SetFillColor(...)
  let r = s:float.new(get(a:000, 0))
  let g = s:float.new(get(a:000, 1, -1))
  let b = s:float.new(get(a:000, 2, -1))
  "Set color for all filling operations
  if (s:float.cmp(r, 0) == 0 && s:float.cmp(g, 0) == 0 && s:float.cmp(b, 0) == 0) || s:float.cmp(g, -1) == 0
    let self.FillColor = s:sprintf('%.3f g', s:float.div(r, 255))
  else
    let self.FillColor = s:sprintf('%.3f %.3f %.3f rg', s:float.div(r, 255), s:float.div(g, 255), s:float.div(b, 255))
  endif
  let self.ColorFlag = (self.FillColor != self.TextColor)
  if self.page > 0
    call self._out(self.FillColor)
  endif
endfunction

function s:fpdf.SetTextColor(...)
  let r = s:float.new(get(a:000, 0))
  let g = s:float.new(get(a:000, 1, -1))
  let b = s:float.new(get(a:000, 2, -1))
  "Set color for text
  if (s:float.cmp(r, 0) == 0 && s:float.cmp(g, 0) == 0 && s:float.cmp(b, 0) == 0) || s:float.cmp(g, -1) == 0
    let self.TextColor = s:sprintf('%.3f g', s:float.div(r, 255))
  else
    let self.TextColor = s:sprintf('%.3f %.3f %.3f rg', s:float.div(r, 255), s:float.div(g, 255), s:float.div(b, 255))
  endif
  let self.ColorFlag = (self.FillColor != self.TextColor)
endfunction

function s:fpdf.GetStringWidthPoint(s)
  "Get width of a string in the current font
  let cw = self.CurrentFont['cw']
  let w = 0
  for c in split(a:s, '\zs')
    let w += has_key(cw, char2nr(c)) ? cw[char2nr(c)] : (500 * s:mb_strwidth(c))
  endfor
  return w
endfunction

function s:fpdf.GetStringWidth(s)
  return s:float.div(s:float.mul(self.GetStringWidthPoint(a:s), self.FontSize), 1000)
endfunction

function s:fpdf.SetLineWidth(width)
  "Set line width
  let self.LineWidth = s:float.new(a:width)
  if self.page > 0
    call self._out(s:sprintf('%.2f w', s:float.mul(a:width, self.k)))
  endif
endfunction

function s:fpdf.Line(x1, y1, x2, y2)
  "Draw a line
  call self._out(s:sprintf('%.2f %.2f m %.2f %.2f l S', s:float.mul(a:x1, self.k), s:float.mul(s:float.sub(self.h, a:y1), self.k), s:float.mul(a:x2, self.k), s:float.mul(s:float.sub(self.h, a:y2), self.k)))
endfunction

function s:fpdf.Rect(...)
  let x = get(a:000, 0)
  let y = get(a:000, 1)
  let w = get(a:000, 2)
  let h = get(a:000, 3)
  let style = get(a:000, 4, '')
  "Draw a rectangle
  if style == 'F'
    let op = 'f'
  elseif style == 'FD' || style == 'DF'
    let op = 'B'
  else
    let op = 'S'
  endif
  call self._out(s:sprintf('%.2f %.2f %.2f %.2f re %s', s:float.mul(x, self.k), s:float.mul(s:float.sub(self.h, y), self.k), s:float.mul(w, self.k), s:float.mul(s:float.sub(0, h), self.k), op))
endfunction

function s:fpdf.AddFont(...)
  let family = get(a:000, 0)
  let style = get(a:000, 1, '')
  let file = get(a:000, 2, '')
  "Add a TrueType or Type1 font
  let family = tolower(family)
  if file == ''
    let file = substitute(family, ' ', '' ,'g') . tolower(style) . '.vim'
  endif
  if family == 'arial'
    let family = 'helvetica'
  endif
  let style = toupper(style)
  if style == 'IB'
    let style = 'BI'
  endif
  let fontkey = family . style
  if has_key(self.fonts, fontkey)
    throw 'Font already added: ' . family . ' ' . style
  endif
  unlet! s:fpdf._font
  call s:include(self._getfontpath() . file)
  " _font should have type, name, desc, up, ut, cw, enc, file, diff
  if !has_key(s:fpdf, '_font')
    throw 'Could not include font definition file'
  endif
  let i = len(self.fonts) + 1
  let self.fonts[fontkey] = s:fpdf._font
  let diff = s:fpdf._font['diff']
  if diff != 0
    "Search existing encodings
    let d = 0
    let nb = len(self.diffs)
    for i in range(nb)
      if self.diffs[i] == diff
        let d = i
        break
      endif
    endfor
    if d == 0
      let d = nb + 1
      call add(self.diffs, diff)
    endif
    let self.fonts[fontkey]['diff'] = d
  endif
  if file != ''
    if type == 'TrueType'
      let self.FontFiles[file] = {'length1' : originalsize}
    else
      let self.FontFiles[file] = {'length1' : size1, 'length2' : size2}
    endif
  endif
endfunction

let g:fpdf_charwidths = {}

function s:fpdf.SetFont(...)
  let family = get(a:000, 0)
  let style = get(a:000, 1, '')
  let size = s:float.new(get(a:000, 2, 0))

  "Select a font; size given in points

  let family = tolower(family)
  if family == ''
    let family = self.FontFamily
  endif
  if family== 'arial'
    let family = 'helvetica'
  elseif family == 'symbol' || family == 'zapfdingbats'
    let style = ''
  endif
  let style = toupper(style)
  if style =~# 'U'
    let self.underline = s:true
    let style = substitute(style, 'U', '', 'G')
  else
    let self.underline = s:false
  endif
  if style == 'IB'
    let style = 'BI'
  endif
  if s:float.cmp(size, 0) == 0
    let size = self.FontSizePt
  endif
  "Test if font is already selected
  if self.FontFamily == family && self.FontStyle == style && s:float.cmp(self.FontSizePt, size) == 0
    return
  endif
  "Test if used for the first time
  let fontkey = family . style
  if !has_key(self.fonts, fontkey)
    "Check if one of the standard fonts
    if has_key(self.CoreFonts, fontkey)
      if !has_key(g:fpdf_charwidths, fontkey)
        "Load metric file
        let file = family
        if family == 'times' || family == 'helvetica'
          let file .= tolower(style)
        endif
        call s:include(self._getfontpath() . file . '.vim')
        if !has_key(g:fpdf_charwidths, fontkey)
          throw 'Could not include font metric file'
        endif
      endif
      let i = len(self.fonts) + 1
      let self.fonts[fontkey] = {'i' : i, 'type' : 'core', 'name' : self.CoreFonts[fontkey], 'up' : -100, 'ut' : 50, 'cw' : g:fpdf_charwidths[fontkey]}
    else
      throw 'Undefined font: ' . family . ' ' . style
    endif
  endif
  "Select it
  let self.FontFamily = family
  let self.FontStyle = style
  let self.FontSizePt = size
  let self.FontSize = s:float.div(size, self.k)
  let self.CurrentFont = self.fonts[fontkey]
  if self.page > 0
    call self._out(s:sprintf('BT /F%d %.2f Tf ET', self.CurrentFont['i'], self.FontSizePt))
  endif
endfunction

function s:fpdf.SetFontSize(size)
  "Set font size in points
  if s:float.cmp(self.FontSizePt, a:size) == 0
    return
  endif
  let self.FontSizePt = s:float.new(a:size)
  let self.FontSize = s:float.div(a:size, self.k)
  if self.page > 0
    call self._out(s:sprintf('BT /F%d %.2f Tf ET', self.CurrentFont['i'], self.FontSizePt))
  endif
endfunction

function s:fpdf.AddLink()
  "Create a new internal link
  let n = len(self.links) + 1
  let self.links[n] = [0, 0]
  return n
endfunction

function s:fpdf.SetLink(...)
  let link = get(a:000, 0)
  let y = s:float.new(get(a:000, 1, 0))
  let page = get(a:000, 2, -1)
  "Set destination of internal link
  if s:float.cmp(y, -1) == 0
    let y = self.y
  endif
  if page == -1
    let page = self.page
  endif
  let self.links[link] = [page, y]
endfunction

function s:fpdf.Link(x, y, w, h, link)
  "Put a link on the page
  if !has_key(self.PageLinks, self.page)
    let self.PageLinks[self.page] = []
  endif
  call add(self.PageLinks[self.page], [s:float.mul(a:x, self.k), s:float.sub(self.hPt, s:float.mul(a:y, self.k)), s:float.mul(a:w, self.k), s:float.mul(a:h, self.k), a:link])
endfunction

function s:fpdf.Text(x, y, txt)
  "Output a string
  let s = s:sprintf('BT %.2f %.2f Td %s Tj ET', s:float.mul(a:x, self.k), s:float.mul(s:float.sub(self.h, a:y), self.k) self._textstring(a:txt))
  if self.underline && a:txt != ''
    let s .= ' ' . self._dounderline(a:x, a:y, a:txt)
  endif
  if(self.ColorFlag)
    let s = 'q ' . self.TextColor . ' ' . s . ' Q'
  endif
  call self._out(s)
endfunction

function s:fpdf.AcceptPageBreak()
  "Accept automatic page break or not
  return self.AutoPageBreak
endfunction

function s:fpdf.Cell(...)
  let w = s:float.new(get(a:000, 0))
  let h = s:float.new(get(a:000, 1))
  let txt = get(a:000, 2, '')
  let border = get(a:000, 3, 0)
  let ln = get(a:000, 4, 0)
  let align = get(a:000, 5, '')
  let fill = get(a:000, 6, 0)
  let link = get(a:000, 7, '')

  "Output a cell
  let k = self.k
  if s:float.cmp(s:float.add(self.y, h), self.PageBreakTrigger) > 0 && !self.InFooter && self.AcceptPageBreak()
    "Automatic page break
    let x = self.x
    let ws = self.ws
    if s:float.cmp(ws, 0) > 0
      let self.ws = s:float.new(0)
      call self._out('0 Tw')
    endif
    call self.AddPage(self.CurOrientation)
    let self.x = x
    if s:float.cmp(ws, 0) > 0
      let self.ws = ws
      call self._out(s:sprintf('%.3f Tw', s:float.mul(ws, k)))
    endif
  endif
  if s:float.cmp(w, 0) == 0
    let w = s:float.sub(s:float.sub(self.w, self.rMargin), self.x)
  endif
  let s = ''
  if fill == 1 || border == 1
    if fill == 1
      let op = (border==1) ? 'B' : 'f'
    else
      let op = 'S'
    endif
    let s = s:sprintf('%.2f %.2f %.2f %.2f re %s ', s:float.mul(self.x, k), s:float.mul(s:float.sub(self.h, self.y), k), s:float.mul(w, k), s:float.mul(s:float.sub(0, h), k), op)
  endif
  if s:is_string(border)
    let x = self.x
    let y = self.y
    if border =~? 'L'
      let s .= s:sprintf('%.2f %.2f m %.2f %.2f l S ', s:float.mul(x, k), s:float.mul(s:float.sub(self.h, y), k), s:float.mul(x, k), s:float.mul(s:float.sub(self.h, s:float.add(y, h)), k))
    endif
    if border =~? 'T'
      let s .= s:sprintf('%.2f %.2f m %.2f %.2f l S ', s:float.mul(x, k), s:float.mul(s:float.sub(self.h, y), k), s:float.mul(s:float.add(x, w), k), s:float.mul(s:float.sub(self.h, y), k))
    endif
    if border =~? 'R'
      let s .= s:sprintf('%.2f %.2f m %.2f %.2f l S ', s:float.mul(s:float.add(x, w), k), s:float.mul(s:float.sub(self.h, y), k), s:float.mul(s:float.add(x, w), k), s:float.mul(s:float.sub(self.h, s:float.add(y, h)), k))
    endif
    if border =~? 'B'
      let s .= s:sprintf('%.2f %.2f m %.2f %.2f l S ', s:float.mul(x, k), s:float.mul(s:float.sub(self.h, s:float.add(y, h)), k), s:float.mul(s:float.add(x, w), k), s:float.mul(s:float.sub(self.h, s:float.add(y, h)), k))
    endif
  endif
  if txt != ''
    if align ==? 'R'
      let dx = s:float.sub(s:float.sub(w, self.cMargin), self.GetStringWidth(txt))
    elseif align ==? 'C'
      let dx = s:float.div(s:float.sub(w, self.GetStringWidth(txt)), 2)
    else
      let dx = self.cMargin
    endif
    if self.ColorFlag
      let s .= 'q ' . self.TextColor . ' '
    endif
    let s .= s:sprintf('BT %.2f %.2f Td %s Tj ET', s:float.mul(s:float.add(self.x, dx), k), s:float.mul(s:float.sub(self.h, s:float.add(s:float.add(self.y, s:float.mul('.5', h)), s:float.mul('.3', self.FontSize))), k), self._textstring(txt))
    if self.underline
      let s .= ' ' . self._dounderline(s:float.add(self.x, dx), s:float.add(s:float.add(self.y, s:float.mul('.5', h)), s:float.mul('.3', self.FontSize)), txt)
    endif
    if self.ColorFlag
      let s .= ' Q'
    endif
    if link != ''
      call self.Link(s:float.add(self.x, dx), s:float.sub(s:float.add(self.y, s:float.mul('.5', h)), s:float.mul('.5', self.FontSize)), self.GetStringWidth(txt), self.FontSize, link)
    endif
  endif
  if s != ''
    call self._out(s)
  endif
  let self.lasth = h
  if ln > 0
    "Go to next line
    let self.y = s:float.add(self.y, h)
    if ln == 1
      let self.x = self.lMargin
    endif
  else
    let self.x = s:float.add(self.x, w)
  endif
endfunction

function s:fpdf.MultiCell(...)
  let w = s:float.cast(get(a:000, 0))
  let h = s:float.cast(get(a:000, 1))
  let txt = get(a:000, 2)
  let border = get(a:000, 3, 0)
  let align = get(a:000, 4, 'J')
  let fill = get(a:000, 5, 0)

  "Output text with automatic or explicit line breaks
  let cw = self.CurrentFont['cw']
  if s:float.cmp(w, 0) == 0
    let w = s:float.sub(s:float.sub(self.w, self.rMargin), self.x)
  endif
  let wmax = s:float.div(s:float.mul(s:float.sub(w, s:float.mul(2, self.cMargin)), 1000), self.FontSize)
  let s = substitute(txt, "\r", '', 'g')
  let nb = s:mb_strlen(s)
  if nb > 0 && s:mb_substr(s, nb - 1, 1) == "\n"
    let nb -= 1
  endif
  let b = 0
  let b2 = ''
  if border != ''
    if border == 1
      let border = 'LTRB'
      let b = 'LRT'
      let b2 = 'LR'
    else
      let b2 = ''
      if border =~? 'L'
        let b2 .= 'L'
      endif
      if border =~? 'R'
        let b2 .= 'R'
      endif
      let b = (border =~? 'T') ? (b2 . 'T') : b2
    endif
  endif
  let sep = -1
  let i = 0
  let j = 0
  let l = 0
  let ns = 0
  let nl = 1
  while i < nb
    "Get next character
    let c = s:mb_substr(s, i, 1)
    if c == "\n"
      "Explicit line break
      if s:float.cmp(ws, 0) > 0
        let self.ws = s:float.new(0)
        call self._out('0 Tw')
      endif
      call self.Cell(w,h,s:mb_substr(s,j,i-j),b,2,align,fill)
      let i += 1
      let sep = -1
      let j = i
      let l = 0
      let ns = 0
      let nl += 1
      if border != '' && nl == 2
        let b = b2
      endif
      continue
    endif
    if c == ' '
      let sep = i
      let ls = l
      let ns += 1
    endif
    let l += self.GetStringWidthPoint(c)
    if s:float.cmp(l, wmax) > 0
      "Automatic line break
      if sep == -1
        if i == j
          let i += 1
        endif
        if s:float.cmp(self.ws, 0) > 0
          let self.ws = s:float.new(0)
          call self._out('0 Tw')
        endif
        call self.Cell(w,h,s:mb_substr(s,j,i-j),b,2,align,fill)
      else
        if align ==? 'J'
          if ns > 1
            let self.ws = s:float.div(s:float.mul(s:float.div(s:float.sub(wmax, ls), 1000), self.FontSize), ns - 1)
          else
            let self.ws = s:float.new(0)
          endif
          call self._out(s:sprintf('%.3f Tw',s:float.mul(self.ws, self.k)))
        endif
        call self.Cell(w,h,s:mb_substr(s,j,sep-j),b,2,align,fill)
        let i = sep + 1
      endif
      let sep = -1
      let j = i
      let l = 0
      let ns = 0
      let nl += 1
      if border != '' && nl == 2
        let b = b2
      endif
    else
      let i += 1
    endif
  endwhile
  "Last chunk
  if s:float.cmp(self.ws, 0) > 0
    let self.ws = s:float.new(0)
    call self._out('0 Tw')
  endif
  if border =~? 'B'
    let b .= 'B'
  endif
  call self.Cell(w,h,s:mb_substr(s,j,i-j),b,2,align,fill)
  let self.x = self.lMargin
endfunction

function s:fpdf.Write(...)
  let h = s:float.new(get(a:000, 0))
  let txt = get(a:000, 1)
  let link = get(a:000, 2, '')

  "Output text in flowing mode
  let w = s:float.sub(s:float.sub(self.w, self.rMargin), self.x)
  let wmax = s:float.div(s:float.mul(s:float.sub(w, s:float.mul(2, self.cMargin)), 1000), self.FontSize)
  let s = substitute(txt, "\r", '', 'g')
  let nb = s:mb_strlen(s)
  let sep = -1
  let i = 0
  let j = 0
  let l = 0
  let nl = 1
  while i < nb
    "Get next character
    let c = s:mb_substr(s, i, 1)
    if c == "\n"
      "Explicit line break
      call self.Cell(w, h, s:mb_substr(s, j, i-j), 0, 2, '', 0, link)
      let i += 1
      let sep = -1
      let j = i
      let l = 0
      if nl == 1
        let self.x = self.lMargin
        let w = s:float.sub(s:float.sub(self.w, self.rMargin), s:float.sub(0, self.x))
        let wmax = s:float.div(s:float.mul(s:float.sub(w, s:float.mul(2, self.cMargin)), 1000), self.FontSize)
      endif
      let nl += 1
      continue
    endif
    if c == ' '
      let sep = i
    endif
    let l += self.GetStringWidthPoint(c)
    if s:float.cmp(l, wmax) > 0
      "Automatic line break
      if sep == -1
        if s:float.cmp(self.x, self.lMargin) > 0
          "Move to next line
          let self.x = self.lMargin
          let self.y = s:float.add(self.y, h)
          let w = s:float.sub(s:float.sub(self.w, self.rMargin), self.x)
          let wmax = s:float.div(s:float.mul(s:float.sub(w, s:float.mul(2, self.cMargin)), 1000), self.FontSize)
          let i += 1
          let nl += 1
          continue
        endif
        if i == j
          let i += 1
        endif
        call self.Cell(w, h, s:mb_substr(s, j, i - j), 0, 2, '', 0, link)
      else
        call self.Cell(w, h, s:mb_substr(s, j, sep - j), 0, 2, '', 0, link)
        let i = sep + 1
      endif
      let sep = -1
      let j = i
      let l = 0
      if nl == 1
        let self.x = self.lMargin
        let w = s:float.sub(s:float.sub(self.w, self.rMargin), self.x)
        let wmax = s:float.div(s:float.mul(s:float.sub(w, s:float.mul(2, self.cMargin)), 1000), self.FontSize)
      endif
      let nl += 1
    else
      let i += 1
    endif
  endwhile
  "Last chunk
  if i != j
    call self.Cell(s:float.mul(s:float.div(l, 1000), self.FontSize), h, s:mb_substr(s, j), 0, 0, '', 0, link)
  endif
endfunction

"function Image($file,$x,$y,$w=0,$h=0,$type='',$link='')
"{
"	//Put an image on the page
"	if(!isset($this->images[$file]))
"	{
"		//First use of image, get info
"		if($type=='')
"		{
"			$pos=strrpos($file,'.');
"			if(!$pos)
"				$this->Error('Image file has no extension and no type was specified: '.$file);
"			$type=substr($file,$pos+1);
"		}
"		$type=strtolower($type);
"		$mqr=get_magic_quotes_runtime();
"		set_magic_quotes_runtime(0);
"		if($type=='jpg' || $type=='jpeg')
"			$info=$this->_parsejpg($file);
"		elseif($type=='png')
"			$info=$this->_parsepng($file);
"		else
"		{
"			//Allow for additional formats
"			$mtd='_parse'.$type;
"			if(!method_exists($this,$mtd))
"				$this->Error('Unsupported image type: '.$type);
"			$info=$this->$mtd($file);
"		}
"		set_magic_quotes_runtime($mqr);
"		$info['i']=count($this->images)+1;
"		$this->images[$file]=$info;
"	}
"	else
"		$info=$this->images[$file];
"	//Automatic width and height calculation if needed
"	if($w==0 && $h==0)
"	{
"		//Put image at 72 dpi
"		$w=$info['w']/$this->k;
"		$h=$info['h']/$this->k;
"	}
"	if($w==0)
"		$w=$h*$info['w']/$info['h'];
"	if($h==0)
"		$h=$w*$info['h']/$info['w'];
"	$this->_out(sprintf('q %.2f 0 0 %.2f %.2f %.2f cm /I%d Do Q',$w*$this->k,$h*$this->k,$x*$this->k,($this->h-($y+$h))*$this->k,$info['i']));
"	if($link)
"		$this->Link($x,$y,$w,$h,$link);
"}

function s:fpdf.Ln(...)
  let h = get(a:000, 0, '')
  "Line feed; default value is last cell height
  let self.x = self.lMargin
  if s:is_string(h)
    let self.y = s:float.add(self.y, self.lasth)
  else
    let self.y = s:float.add(self.y, h)
  endif
endfunction

function s:fpdf.GetX()
  "Get x position
  return self.x
endfunction

function s:fpdf.SetX(x)
  let x = s:float.new(a:x)
  "Set x position
  if s:float.cmp(x, 0) >= 0
    let self.x = x
  else
    let self.x = s:float.add(self.w, x)
  endif
endfunction

function s:fpdf.GetY()
  "Get y position
  return self.y
endfunction

function s:fpdf.SetY(y)
  let y = s:float.new(a:y)
  "Set y position and reset x
  let self.x = self.lMargin
  if s:float.cmp(y, 0) >= 0
    let self.y = y
  else
    let self.y = s:float.add(self.h, a:y)
  endif
endfunction

function s:fpdf.SetXY(x,y)
  "Set x and y positions
  call self.SetY(a:y)
  call self.SetX(a:x)
endfunction

function s:fpdf.Output(...)
  let name = get(a:000, 0, '')

  "Output PDF to some destination
  "Finish document if necessary
  if self.state < 3
    call self.Close()
  endif
  return self.buffer
endfunction

"*******************************************************************************
"                                                                              *
"                              Protected methods                               *
"                                                                              *
"******************************************************************************/

function s:fpdf._getfontpath()
  if !exists('g:FPDF_FONTPATH') && isdirectory(s:dirname(s:__file__) . '/font')
    let g:FPDF_FONTPATH = s:dirname(s:__file__) . '/font/'
  endif
  return exists('g:FPDF_FONTPATH') ? g:FPDF_FONTPATH : ''
endfunction

function s:fpdf._putpages()
  let nb = self.page
  if get(self, 'vAliasNbPages', '') != ''
    "Replace number of pages
    for n in range(1, nb)
      let self.pages[n] = substitute(self.pages[n], self.vAliasNbPages, nb, 'g')
    endfor
  endif
  if self.DefOrientation == 'P'
    let wPt = self.fwPt
    let hPt = self.fhPt
  else
    let wPt = self.fhPt
    let hPt = self.fwPt
  endif
  let filter = self.compress ? '/Filter /FlateDecode ' : ''
  for n in range(1, nb)
    "Page
    call self._newobj()
    call self._out('<</Type /Page')
    call self._out('/Parent 1 0 R')
    if has_key(self.OrientationChanges, n)
      call self._out(s:sprintf('/MediaBox [0 0 %.2f %.2f]', hPt, wPt))
    endif
    call self._out('/Resources 2 0 R')
    if has_key(self.PageLinks, n)
      "Links
      let annots = '/Annots ['
      for pl in self.PageLinks[n]
        let rect = s:sprintf('%.2f %.2f %.2f %.2f', pl[0], pl[1], s:float.add(pl[0], pl[2]), s:float.sub(pl[1], pl[3]))
        let annots .= '<</Type /Annot /Subtype /Link /Rect [' . rect . '] /Border [0 0 0] '
        if s:is_string(pl[4])
          let annots .= '/A <</S /URI /URI ' . self._textstring(pl[4]) . '>>>>'
        else
          let l = self.links[pl[4]]
          let h = has_key(self.OrientationChanges, l[0]) ? wPt : hPt
          let annots .= s:sprintf('/Dest [%d 0 R /XYZ 0 %.2f null]>>', 1 + 2 * l[0], s:float.sub(h, s:float.mul(l[1], self.k)))
        endif
      endfor
      call self._out(annots . ']')
    endif
    call self._out('/Contents ' . (self.n + 1) . ' 0 R>>')
    call self._out('endobj')
    "Page content
    let p = self.compress ? s:gzcompress(self.pages[n]) : self.pages[n]
    call self._newobj()
    call self._out('<<' . filter . '/Length ' . strlen(p) . '>>')
    call self._putstream(p)
    call self._out('endobj')
  endfor
  "Pages root
  let self.offsets[1] = strlen(self.buffer)
  call self._out('1 0 obj')
  call self._out('<</Type /Pages')
  let kids = '/Kids ['
  for i in range(nb)
    let kids .= (3 + 2 * i) . ' 0 R '
  endfor
  call self._out(kids . ']')
  call self._out('/Count ' . nb)
  call self._out(s:sprintf('/MediaBox [0 0 %.2f %.2f]', wPt, hPt))
  call self._out('>>')
  call self._out('endobj')
endfunction

function s:fpdf._putfonts()
  let nf = self.n
  for diff in self.diffs
    "Encodings
    call self._newobj()
    call self._out('<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences [' . diff . ']>>')
    call self._out('endobj')
  endfor
  let mqr = s:get_magic_quotes_runtime()
  call s:set_magic_quotes_runtime(0)
  for [file, info] in items(self.FontFiles)
    "Font file embedding
    call self._newobj()
    let self.FontFiles[file]['n'] = self.n
    let font = s:fread(self._getfontpath() . file, 'rb', 1)
    let compressed = (file =~ '\.z$')
    if !compressed && has_key(info, 'length2')
      let header = (char2nr(font[0])==128)
      if header
        "Strip first binary header
        let font = font[6 : ]
      endif
      if header && char2nr(font[info['length1']])==128
        "Strip second binary header
        let font = font[0 : info['length1']] . font[info['length1'] + 6 : ]
      endif
    endif
    call self._out('<</Length ' . strlen(font))
    if compressed
      call self._out('/Filter /FlateDecode')
    endif
    call self._out('/Length1 ' . info['length1'])
    if has_key(info, 'length2')
      call self._out('/Length2 ' . info['length2'] . ' /Length3 0')
    endif
    call self._out('>>')
    call self._putstream(font)
    call self._out('endobj')
  endfor
  call s:set_magic_quotes_runtime(mqr)
  for [k, font] in items(self.fonts)
    "Font objects
    let self.fonts[k]['n'] = self.n + 1
    let type = font['type']
    let name = font['name']
    if type=='core'
      "Standard font
      call self._newobj()
      call self._out('<</Type /Font')
      call self._out('/BaseFont /' . name)
      call self._out('/Subtype /Type1')
      if name != 'Symbol' && name != 'ZapfDingbats'
        call self._out('/Encoding /WinAnsiEncoding')
      endif
      call self._out('>>')
      call self._out('endobj')
    elseif type=='Type1' || type=='TrueType'
      "Additional Type1 or TrueType font
      call self._newobj()
      call self._out('<</Type /Font')
      call self._out('/BaseFont /' . name)
      call self._out('/Subtype /' . type)
      call self._out('/FirstChar 32 /LastChar 255')
      call self._out('/Widths ' . (self.n + 1) . ' 0 R')
      call self._out('/FontDescriptor ' . (self.n + 2) . ' 0 R')
      if font['enc']
        if has_key(font['diff'])
          call self._out('/Encoding ' . (nf + font['diff']) . ' 0 R')
        else
          call self._out('/Encoding /WinAnsiEncoding')
        endif
      endif
      call self._out('>>')
      call self._out('endobj')
      "Widths
      call self._newobj()
      let cw = font['cw']
      let s = '['
      for i in range(32, 255)
        let s .=  cw[i] . ' '
      endfor
      call self._out(s . ']')
      call self._out('endobj')
      "Descriptor
      call self._newobj()
      let s = '<</Type /FontDescriptor /FontName /' . name
      for [k, v] in items(font['desc'])
        let s .= ' /' . k . ' ' . v
      endfor
      let file = font['file']
      if file
        let s .= ' /FontFile' . (type=='Type1' ? '' : '2') . ' ' . self.FontFiles[file]['n'] . ' 0 R'
      endif
      call self._out(s . '>>')
      call self._out('endobj')
    else
      "Allow for additional types
      let mtd = '_put' . type
      if !has_key(self, mtd)
        throw 'Unsupported font type: ' . type
      endif
      call self[mtd](font)
    endif
  endfor
endfunction

function s:fpdf._putimages()
  let filter = (self.compress) ? '/Filter /FlateDecode ' : ''
  for [file, info] in items(self.images)
    call self._newobj()
    let self.images[file]['n'] = self.n
    call self._out('<</Type /XObject')
    call self._out('/Subtype /Image')
    call self._out('/Width ' . info['w'])
    call self._out('/Height ' . info['h'])
    if info['cs']=='Indexed'
      call self._out('/ColorSpace [/Indexed /DeviceRGB ' . (strlen(info['pal']) / 3 - 1) . ' ' . (self.n + 1) . ' 0 R]')
    else
      call self._out('/ColorSpace /' . info['cs'])
      if info['cs'] == 'DeviceCMYK'
        call self._out('/Decode [1 0 1 0 1 0 1 0]')
      endif
    endif
    call self._out('/BitsPerComponent ' . info['bpc'])
    if has_key(info, 'f')
      call self._out('/Filter /' . info['f'])
    endif
    if has_key(info, 'parms')
      call self._out(info['parms'])
    endif
    if has_key(info, 'trns') && s:is_array(info['trns'])
      let trns = ''
      for t in info['trns']
        let trns .= t . ' ' . t . ' '
      endfor
      call self._out('/Mask [' . trns . ']')
    endif
    call self._out('/Length ' . strlen(info['data']) . '>>')
    call self._putstream(info['data'])
    unlet self.images[file]['data']
    call self._out('endobj')
    "Palette
    if info['cs'] == 'Indexed'
      call self._newobj()
      let pal = (self.compress) ? s:gzcompress(info['pal']) : info['pal']
      call self._out('<<' . filter . '/Length ' . strlen(pal) . '>>')
      call self._putstream(pal)
      call self._out('endobj')
    endif
  endfor
endfunction

function s:fpdf._putxobjectdict()
  for image in values(self.images)
    call self._out('/I' . image['i'] . ' ' . image['n'] . ' 0 R')
  endfor
endfunction

function s:fpdf._putresourcedict()
  call self._out('/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]')
  call self._out('/Font <<')
  for font in values(self.fonts)
    call self._out('/F' . font['i'] . ' ' . font['n'] . ' 0 R')
  endfor
  call self._out('>>')
  call self._out('/XObject <<')
  call self._putxobjectdict()
  call self._out('>>')
endfunction

function s:fpdf._putresources()
  call self._putfonts()
  call self._putimages()
  "Resource dictionary
  let self.offsets[2] = strlen(self.buffer)
  call self._out('2 0 obj')
  call self._out('<<')
  call self._putresourcedict()
  call self._out('>>')
  call self._out('endobj')
endfunction

function s:fpdf._putinfo()
  call self._out('/Producer ' . self._textstring(printf('fpdf-vim %s (FPDF %s)', s:FPDF_VIM_VERSION, s:FPDF_VERSION)))
  if self.title != ''
    call self._out('/Title ' . self._textstring(self.title))
  endif
  if self.subject != ''
    call self._out('/Subject ' . self._textstring(self.subject))
  endif
  if self.author != ''
    call self._out('/Author ' . self._textstring(self.author))
  endif
  if self.keywords != ''
    call self._out('/Keywords ' . self._textstring(self.keywords))
  endif
  if self.creator != ''
    call self._out('/Creator ' . self._textstring(self.creator))
  endif
  call self._out('/CreationDate ' . self._textstring('D:' . strftime('%Y%m%d%H%M%S')))
endfunction

function s:fpdf._putcatalog()
  call self._out('/Type /Catalog')
  call self._out('/Pages 1 0 R')
  if self.ZoomMode == 'fullpage'
    call self._out('/OpenAction [3 0 R /Fit]')
  elseif self.ZoomMode=='fullwidth'
    call self._out('/OpenAction [3 0 R /FitH null]')
  elseif self.ZoomMode=='real'
    call self._out('/OpenAction [3 0 R /XYZ null null 1]')
  elseif !s:is_string(self.ZoomMode)
    call self._out('/OpenAction [3 0 R /XYZ null null ' . (self.ZoomMode / 100) . ']')
  endif
  if self.LayoutMode == 'single'
    call self._out('/PageLayout /SinglePage')
  elseif self.LayoutMode == 'continuous'
    call self._out('/PageLayout /OneColumn')
  elseif self.LayoutMode=='two'
    call self._out('/PageLayout /TwoColumnLeft')
  endif
endfunction

function s:fpdf._putheader()
  call self._out('%PDF-' . self.PDFVersion)
endfunction

function s:fpdf._puttrailer()
  call self._out('/Size ' . (self.n + 1))
  call self._out('/Root ' . self.n  . ' 0 R')
  call self._out('/Info ' . (self.n - 1) . ' 0 R')
endfunction

function s:fpdf._enddoc()
  call self._putheader()
  call self._putpages()
  call self._putresources()
  "Info
  call self._newobj()
  call self._out('<<')
  call self._putinfo()
  call self._out('>>')
  call self._out('endobj')
  "Catalog
  call self._newobj()
  call self._out('<<')
  call self._putcatalog()
  call self._out('>>')
  call self._out('endobj')
  "Cross-ref
  let o = strlen(self.buffer)
  call self._out('xref')
  call self._out('0 ' . (self.n + 1))
  call self._out('0000000000 65535 f ')
  for i in range(1, self.n)
    call self._out(s:sprintf('%010d 00000 n ', self.offsets[i]))
  endfor
  "Trailer
  call self._out('trailer')
  call self._out('<<')
  call self._puttrailer()
  call self._out('>>')
  call self._out('startxref')
  call self._out(o)
  call self._out('%%EOF')
  let self.state = 3
endfunction

function s:fpdf._beginpage(orientation)
  let orientation = a:orientation

  let self.page += 1
  let self.pages[self.page] = ''
  let self.state = 2
  let self.x = self.lMargin
  let self.y = self.tMargin
  let self.FontFamily = ''
  "Page orientation
  if !orientation
    let orientation = self.DefOrientation
  else
    let orientation = toupper(orientation[0])
    if orientation != self.DefOrientation
      let self.OrientationChanges[self.page] = s:true
    endif
  endif
  if !s:equal(orientation, self.CurOrientation)
    "Change orientation
    if orientation == 'P'
      let self.wPt = self.fwPt
      let self.hPt = self.fhPt
      let self.w = self.fw
      let self.h = self.fh
    else
      let self.wPt = self.fhPt
      let self.hPt = self.fwPt
      let self.w = self.fh
      let self.h = self.fw
    endif
    let self.PageBreakTrigger = self.h - self.bMargin
    let self.CurOrientation = orientation
  endif
endfunction

function s:fpdf._endpage()
  "End of page contents
  let self.state = 1
endfunction

function s:fpdf._newobj()
  "Begin a new object
  let self.n += 1
  let self.offsets[self.n] = strlen(self.buffer)
  call self._out(self.n . ' 0 obj')
endfunction

function s:fpdf._dounderline(x, y, txt)
  let [x, y, txt] = [a:x, a:y, a:txt]
  "Underline text
  let up = self.CurrentFont['up']
  let ut = self.CurrentFont['ut']
  let w = s:float.add(self.GetStringWidth(txt), s:float.mul(self.ws, s:substr_count(txt, ' ')))
  return s:sprintf('%.2f %.2f %.2f %.2f re f', s:float.mul(x, self.k), s:float.mul(s:float.sub(self.h, s:float.sub(y, s:float.mul(s:float.div(up, 1000), self.FontSize))), self.k), s:float.mul(w, self.k), s:float.mul(s:float.div(s:float.sub(0, ut), 1000), self.FontSizePt))
endfunction

"function _parsejpg($file)
"{
"	//Extract info from a JPEG file
"	$a=GetImageSize($file);
"	if(!$a)
"		$this->Error('Missing or incorrect image file: '.$file);
"	if($a[2]!=2)
"		$this->Error('Not a JPEG file: '.$file);
"	if(!isset($a['channels']) || $a['channels']==3)
"		$colspace='DeviceRGB';
"	elseif($a['channels']==4)
"		$colspace='DeviceCMYK';
"	else
"		$colspace='DeviceGray';
"	$bpc=isset($a['bits']) ? $a['bits'] : 8;
"	//Read whole file
"	$f=fopen($file,'rb');
"	$data='';
"	while(!feof($f))
"		$data.=fread($f,4096);
"	fclose($f);
"	return array('w'=>$a[0],'h'=>$a[1],'cs'=>$colspace,'bpc'=>$bpc,'f'=>'DCTDecode','data'=>$data);
"}

"function _parsepng($file)
"{
"	//Extract info from a PNG file
"	$f=fopen($file,'rb');
"	if(!$f)
"		$this->Error('Can\'t open image file: '.$file);
"	//Check signature
"	if(fread($f,8)!=chr(137).'PNG'.chr(13).chr(10).chr(26).chr(10))
"		$this->Error('Not a PNG file: '.$file);
"	//Read header chunk
"	fread($f,4);
"	if(fread($f,4)!='IHDR')
"		$this->Error('Incorrect PNG file: '.$file);
"	$w=$this->_freadint($f);
"	$h=$this->_freadint($f);
"	$bpc=ord(fread($f,1));
"	if($bpc>8)
"		$this->Error('16-bit depth not supported: '.$file);
"	$ct=ord(fread($f,1));
"	if($ct==0)
"		$colspace='DeviceGray';
"	elseif($ct==2)
"		$colspace='DeviceRGB';
"	elseif($ct==3)
"		$colspace='Indexed';
"	else
"		$this->Error('Alpha channel not supported: '.$file);
"	if(ord(fread($f,1))!=0)
"		$this->Error('Unknown compression method: '.$file);
"	if(ord(fread($f,1))!=0)
"		$this->Error('Unknown filter method: '.$file);
"	if(ord(fread($f,1))!=0)
"		$this->Error('Interlacing not supported: '.$file);
"	fread($f,4);
"	$parms='/DecodeParms <</Predictor 15 /Colors '.($ct==2 ? 3 : 1).' /BitsPerComponent '.$bpc.' /Columns '.$w.'>>';
"	//Scan chunks looking for palette, transparency and image data
"	$pal='';
"	$trns='';
"	$data='';
"	do
"	{
"		$n=$this->_freadint($f);
"		$type=fread($f,4);
"		if($type=='PLTE')
"		{
"			//Read palette
"			$pal=fread($f,$n);
"			fread($f,4);
"		}
"		elseif($type=='tRNS')
"		{
"			//Read transparency info
"			$t=fread($f,$n);
"			if($ct==0)
"				$trns=array(ord(substr($t,1,1)));
"			elseif($ct==2)
"				$trns=array(ord(substr($t,1,1)),ord(substr($t,3,1)),ord(substr($t,5,1)));
"			else
"			{
"				$pos=strpos($t,chr(0));
"				if($pos!==false)
"					$trns=array($pos);
"			}
"			fread($f,4);
"		}
"		elseif($type=='IDAT')
"		{
"			//Read image data block
"			$data.=fread($f,$n);
"			fread($f,4);
"		}
"		elseif($type=='IEND')
"			break;
"		else
"			fread($f,$n+4);
"	}
"	while($n);
"	if($colspace=='Indexed' && empty($pal))
"		$this->Error('Missing palette in '.$file);
"	fclose($f);
"	return array('w'=>$w,'h'=>$h,'cs'=>$colspace,'bpc'=>$bpc,'f'=>'FlateDecode','parms'=>$parms,'pal'=>$pal,'trns'=>$trns,'data'=>$data);
"}

" XXX:
function s:fpdf._freadint(f)
  "Read a 4-byte integer from file
  let a= unpack('Ni', fread(a:f, 4))
  return a['i']
endfunction

function s:fpdf._textstring(s)
  "TODO: encoding
  "Format a text string
  if self.CurrentFont['type'] ==? 'type0'
    return '<' . self._bin2hex(a:s) . '>'
  else
    return '(' . self._escape(a:s) . ')'
  endif
endfunction

function s:fpdf._escape(s)
  "Add \ before \, ( and )
  let s = substitute(a:s, '\\', '\\\\', 'g')
  let s = substitute(a:s, '(', '\\(', 'g')
  let s = substitute(a:s, ')', '\\)', 'g')
  return a:s
endfunction

function s:fpdf._bin2hex(s)
  return join(map(split(a:s, '\zs'), 'self.nr2utf16hex(char2nr(v:val))'), '')
endfunction

function s:fpdf._putstream(s)
  call self._out('stream')
  call self._out(a:s)
  call self._out('endstream')
endfunction

function s:fpdf._out(s)
  "Add a line to the document
  if self.state == 2
    let self.pages[self.page] .= a:s . "\n"
  else
    let self.buffer .= a:s . "\n"
  endif
endfunction



"-----------------------------------------------------------
" MBFPDF features
"-----------------------------------------------------------

" Encoding & CMap List (CMap information from Acrobat Reader Resource/CMap folder)
let s:fpdf.MBCMAP = {
      \ 'UniCNS' : {'CMap' : 'UniCNS-UTF16-H', 'Ordering' : 'CNS1',   'Supplement' : 0},
      \ 'UniGB'  : {'CMap' : 'UniGB-UTF16-H',  'Ordering' : 'GB1',    'Supplement' : 2},
      \ 'UniKS'  : {'CMap' : 'UniKS-UTF16-H',  'Ordering' : 'Korea1', 'Supplement' : 0},
      \ 'UniJIS' : {'CMap' : 'UniJIS-UTF16-H', 'Ordering' : 'Japan1', 'Supplement' : 5},
      \ }

let s:fpdf.MBTTFDEF_MONO = {
      \ 'ut' : 74,
      \ 'up' : -66,
      \ 'cw' : {
      \   char2nr(' '):500  ,char2nr('!'):500  ,char2nr('"'):500  ,char2nr('#'):500  ,char2nr('$'):500  ,char2nr('%'):500  ,char2nr('&'):500  ,
      \   char2nr("'"):500  ,char2nr('('):500  ,char2nr(')'):500  ,char2nr('*'):500  ,char2nr('+'):500  ,char2nr(','):500  ,char2nr('-'):500  ,
      \   char2nr('.'):500  ,char2nr('/'):500  ,char2nr('0'):500  ,char2nr('1'):500  ,char2nr('2'):500  ,char2nr('3'):500  ,char2nr('4'):500  ,
      \   char2nr('5'):500  ,char2nr('6'):500  ,char2nr('7'):500  ,char2nr('8'):500  ,char2nr('9'):500  ,char2nr(':'):500  ,char2nr(';'):500  ,
      \   char2nr('<'):500  ,char2nr('='):500  ,char2nr('>'):500  ,char2nr('?'):500  ,char2nr('@'):500  ,char2nr('A'):500  ,char2nr('B'):500  ,
      \   char2nr('C'):500  ,char2nr('D'):500  ,char2nr('E'):500  ,char2nr('F'):500  ,char2nr('G'):500  ,char2nr('H'):500  ,char2nr('I'):500  ,
      \   char2nr('J'):500  ,char2nr('K'):500  ,char2nr('L'):500  ,char2nr('M'):500  ,char2nr('N'):500  ,char2nr('O'):500  ,char2nr('P'):500  ,
      \   char2nr('Q'):500  ,char2nr('R'):500  ,char2nr('S'):500  ,char2nr('T'):500  ,char2nr('U'):500  ,char2nr('V'):500  ,char2nr('W'):500  ,
      \   char2nr('X'):500  ,char2nr('Y'):500  ,char2nr('Z'):500  ,char2nr('['):500  ,char2nr('\'):500  ,char2nr(']'):500  ,char2nr('^'):500  ,
      \   char2nr('_'):500  ,char2nr('`'):500  ,char2nr('a'):500  ,char2nr('b'):500  ,char2nr('c'):500  ,char2nr('d'):500  ,char2nr('e'):500  ,
      \   char2nr('f'):500  ,char2nr('g'):500  ,char2nr('h'):500  ,char2nr('i'):500  ,char2nr('j'):500  ,char2nr('k'):500  ,char2nr('l'):500  ,
      \   char2nr('m'):500  ,char2nr('n'):500  ,char2nr('o'):500  ,char2nr('p'):500  ,char2nr('q'):500  ,char2nr('r'):500  ,char2nr('s'):500  ,
      \   char2nr('t'):500  ,char2nr('u'):500  ,char2nr('v'):500  ,char2nr('w'):500  ,char2nr('x'):500  ,char2nr('y'):500  ,char2nr('z'):500  ,
      \   char2nr('{'):500  ,char2nr('|'):500  ,char2nr('}'):500  ,char2nr('~'):500,
      \   },
      \ }

let s:fpdf.MBTTFDEF_PROPORTIONAL = {
      \ 'ut' : 74,
      \ 'up' : -66,
      \ 'cw' : {
      \   char2nr(' '):305  ,char2nr('!'):219  ,'\"':500 ,char2nr('#'):500  ,char2nr('$'):500  ,char2nr('%'):500  ,char2nr('&'):594  ,
      \   char2nr("'"):203 ,char2nr('('):305  ,char2nr(')'):305  ,char2nr('*'):500  ,char2nr('+'):500  ,char2nr(','):203  ,char2nr('-'):500  ,
      \   char2nr('.'):203  ,char2nr('/'):500  ,char2nr('0'):500  ,char2nr('1'):500  ,char2nr('2'):500  ,char2nr('3'):500  ,char2nr('4'):500  ,
      \   char2nr('5'):500  ,char2nr('6'):500  ,char2nr('7'):500  ,char2nr('8'):500  ,char2nr('9'):500  ,char2nr(':'):203  ,char2nr(';'):203  ,
      \   char2nr('<'):500  ,char2nr('='):500  ,char2nr('>'):500  ,char2nr('?'):453  ,char2nr('@'):668  ,char2nr('A'):633  ,char2nr('B'):637  ,
      \   char2nr('C'):664  ,char2nr('D'):648  ,char2nr('E'):566  ,char2nr('F'):551  ,char2nr('G'):680  ,char2nr('H'):641  ,char2nr('I'):246  ,
      \   char2nr('J'):543  ,char2nr('K'):598  ,char2nr('L'):539  ,char2nr('M'):742  ,char2nr('N'):641  ,char2nr('O'):707  ,char2nr('P'):617  ,
      \   char2nr('Q'):707  ,char2nr('R'):625  ,char2nr('S'):602  ,char2nr('T'):590  ,char2nr('U'):641  ,char2nr('V'):633  ,char2nr('W'):742  ,
      \   char2nr('X'):602  ,char2nr('Y'):590  ,char2nr('Z'):566  ,char2nr('['):336  ,'\\':504 ,char2nr(']'):336  ,char2nr('^'):414  ,
      \   char2nr('_'):305  ,char2nr('`'):414  ,char2nr('a'):477  ,char2nr('b'):496  ,char2nr('c'):500  ,char2nr('d'):496  ,char2nr('e'):500  ,
      \   char2nr('f'):305  ,char2nr('g'):461  ,char2nr('h'):500  ,char2nr('i'):211  ,char2nr('j'):219  ,char2nr('k'):461  ,char2nr('l'):211  ,
      \   char2nr('m'):734  ,char2nr('n'):500  ,char2nr('o'):508  ,char2nr('p'):496  ,char2nr('q'):496  ,char2nr('r'):348  ,char2nr('s'):461  ,
      \   char2nr('t'):352  ,char2nr('u'):500  ,char2nr('v'):477  ,char2nr('w'):648  ,char2nr('x'):461  ,char2nr('y'):477  ,char2nr('z'):457  ,
      \   char2nr('{'):234  ,char2nr('|'):234  ,char2nr('}'):234  ,char2nr('~'):414,
      \   },
      \ }

function s:fpdf.AddCIDFont(family, style, name, cw, CMap, registry, ut, up)
  let i = len(self.fonts) + 1
  let fontkey = tolower(a:family) . toupper(a:style)
  let self.fonts[fontkey] = {'i' : i, 'type' : 'Type0', 'name' : a:name, 'up' : a:up, 'ut' : a:ut, 'cw' : a:cw, 'CMap' : a:CMap, 'registry' : a:registry}
endfunction

function s:fpdf.AddMBFont(...)
  let family = get(a:000, 0)
  let cmap = get(a:000, 1)
  let gt = get(a:000, 2, {})

  if !has_key(self.MBCMAP, cmap)
    throw "AddMBFont: ERROR CMap " . cmap . " Undefine."
  endif
  if gt == {}
    let gt = self.MBTTFDEF_MONO
  endif
  let gc = self.MBCMAP[cmap]
  let ut = gt['ut']
  let up = gt['up']
  let cw = gt['cw']
  let cm = gc['CMap']
  let od = gc['Ordering']
  let sp = gc['Supplement']
  let registry = {'ordering' : od, 'supplement' : sp}
  call self.AddCIDFont(family,''  , family                , cw, cm, registry, ut, up)
  call self.AddCIDFont(family,'B' , family . ",Bold"      , cw, cm, registry, ut, up)
  call self.AddCIDFont(family,'I' , family . ",Italic"    , cw, cm, registry, ut, up)
  call self.AddCIDFont(family,'BI', family . ",BoldItalic", cw, cm, registry, ut, up)
endfunction

function s:fpdf.nr2utf16hex(char)
  if a:char == 0xFFFD
    return "FFFD" " replacement character
  elseif a:char < 0x10000
    return printf("%02X%02X", a:char / 0x100, a:char % 0x100)
  else
    let char = a:char - 0x10000
    let w1 = 0xD800 + (char / 0x400)
    let w2 = 0xDC00 + (char % 0x400)
    return printf("%02X%02X%02X%02X", w1 / 0x100, w1 & 0xFF, w2 / 0x100, w2 % 0x100)
  endif
endfunction

function s:fpdf._putType0(font)
  let font = a:font

  "Type0
  call self._newobj()
  call self._out('<</Type /Font')
  call self._out('/Subtype /Type0')
  call self._out('/BaseFont /' . font['name'] . '-' . font['CMap'])
  call self._out('/Encoding /' . font['CMap'])
  call self._out('/DescendantFonts [' . (self.n + 1) . ' 0 R]')
  call self._out('>>')
  call self._out('endobj')
  "CIDFont
  call self._newobj()
  call self._out('<</Type /Font')
  call self._out('/Subtype /CIDFontType0')
  call self._out('/BaseFont /' . font['name'])
  call self._out('/CIDSystemInfo <</Registry (Adobe) /Ordering (' . font['registry']['ordering'] . ') /Supplement ' . font['registry']['supplement'] . '>>')
  call self._out('/FontDescriptor ' . (self.n + 1) . ' 0 R')
  call self._out('/W [1 [ ' . join(values(font['cw']), ' ') . ' ]')
  if font['registry']['ordering'] == 'Japan1'
    call self._out(' 231 325 500 631 [500] 326 389 500')
  endif
  call self._out(']')
  call self._out('>>')
  call self._out('endobj')
  "Font descriptor
  call self._newobj()
  call self._out('<</Type /FontDescriptor')
  call self._out('/FontName /' . font['name'])
  call self._out('/Flags 6')
  call self._out('/FontBBox [0 0 1000 1000]')
  call self._out('/ItalicAngle 0')
  call self._out('/Ascent 1000')
  call self._out('/Descent 0')
  call self._out('/CapHeight 1000')
  call self._out('/StemV 10')
  call self._out('>>')
  call self._out('endobj')
endfunction

