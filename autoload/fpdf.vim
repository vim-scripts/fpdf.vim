"*******************************************************************************
" FPDF                                                                         *
"                                                                              *
" Version: 1.6                                                                 *
" Date:    2008-08-03                                                          *
" Author:  Olivier PLATHEY                                                     *
"******************************************************************************/
"===============================================================================
" fpdf16/license.txt
"-------------------------------------------------------------------------------
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software to use, copy, modify, distribute, sublicense, and/or sell
" copies of the software, and to permit persons to whom the software is
" furnished to do so.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED.
"===============================================================================
" 2008-03-20: ported to vim by Yukihiro Nakadaira <yukihiri.nakadaira@gmail.com>
" 2008-08-13: updated codebase to fpdf1.6
" Last Change: 2008-08-15

function fpdf#import()
  return s:fpdf
endfunction

" temporary variable
let fpdf#font = {}

let s:__file__ = expand("<sfile>:p")

let s:FPDF_VERSION = '1.6'
let s:FPDF_VIM_VERSION = '0.4'

let s:false = 0
let s:true = 1
let s:null = {}

" cast
function! s:float(f)
  if [a:f] == [s:null] || type(a:f) == type(0.0)
    return a:f
  endif
  return str2float(a:f)
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

function! s:substr_count(txt, sub)
  let sub = []
  call substitute(a:txt, a:sub, '\=empty(add(sub, submatch(0)))', 'g')
  return len(sub)
endfunction

let s:fpdf = {}

"var $page;               "current page number
"var $n;                  "current object number
"var $offsets;            "array of object offsets
"var $buffer;             "buffer holding in-memory PDF
"var $pages;              "array containing pages
"var $state;              "current document state
"var $compress;           "compression flag
"var $k;                  "scale factor (number of points in user unit)
"var $DefOrientation;     "default orientation
"var $CurOrientation;     "current orientation
"var $PageFormats;        "available page formats
"var $DefPageFormat;      "default page format
"var $CurPageFormat;      "current page format
"var $PageSizes;          "array storing non-default page sizes
"var $wPt,$hPt;           "dimensions of current page in points
"var $w,$h;               "dimensions of current page in user unit
"var $lMargin;            "left margin
"var $tMargin;            "top margin
"var $rMargin;            "right margin
"var $bMargin;            "page break margin
"var $cMargin;            "cell margin
"var $x,$y;               "current position in user unit
"var $lasth;              "height of last printed cell
"var $LineWidth;          "line width in user unit
"var $fonts;              "array of used fonts
"var $FontFiles;          "array of font files
"var $diffs;              "array of encoding differences
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
"var $images;             "array of used images
"var $PageLinks;          "array of links in pages
"var $links;              "array of internal links
"var $AutoPageBreak;      "automatic page breaking
"var $PageBreakTrigger;   "threshold used to trigger page breaks
"var $InHeader;           "flag set when processing header
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
  "Some checks
  call self._dochecks()
  "Initialization of properties
  let self.page = 0
  let self.n = 2
  let self.offsets = {}
  let self.buffer = ''
  let self.pages = {}
  let self.PageSizes = {}
  let self.state = 0
  let self.fonts = {}
  let self.FontFiles = {}
  let self.diffs = []
  let self.images = {}
  let self.PageLinks = {}
  let self.links = {}
  let self.InHeader = s:false
  let self.InFooter = s:false
  let self.lasth = 0
  let self.FontFamily = ''
  let self.FontStyle = ''
  let self.FontSizePt = 12.0
  let self.underline = s:false
  let self.DrawColor = '0 G'
  let self.FillColor = '0 g'
  let self.TextColor = '0 g'
  let self.ColorFlag = s:false
  let self.ws = 0
  "Scale factor
  if unit == 'pt'
    let self.k = 1.0
  elseif unit == 'mm'
    let self.k = 72.0 / 25.4
  elseif unit == 'cm'
    let self.k = 72.0 / 2.54
  elseif unit == 'in'
    let self.k = 72.0
  else
    throw 'Incorrect unit: ' . unit
  endif
  "Page format
  let self.PageFormats = {'a3':[841.89,1190.55], 'a4':[595.28,841.89], 'a5':[420.94,595.28], 'letter':[612,792], 'legal':[612,1008]}
  if s:is_string(format)
    let l:.format = self._getpageformat(format)
  endif
  let self.DefPageFormat = format
  let self.CurPageFormat = format
  "Page orientation
  let orientation = tolower(orientation)
  if orientation == 'p' || orientation == 'portrait'
    let self.DefOrientation = 'P'
    let self.w = self.DefPageFormat[0]
    let self.h = self.DefPageFormat[1]
  elseif orientation == 'l' || orientation == 'landscape'
    let self.DefOrientation = 'L'
    let self.w = self.DefPageFormat[1]
    let self.h = self.DefPageFormat[0]
  else
    throw 'Incorrect orientation: ' . orientation
  endif
  let self.CurOrientation = self.DefOrientation
  let self.wPt = self.w * self.k
  let self.hPt = self.h * self.k
  "Page margins (1 cm)
  let margin = 28.35 / self.k
  call self.SetMargins(margin, margin)
  "Interior cell margin (1 mm)
  let self.cMargin = margin / 10.0
  "Line width (0.2 mm)
  let self.LineWidth = 0.567 / self.k
  "Automatic page break
  call self.SetAutoPageBreak(s:true, 2.0 * margin)
  "Full width display mode
  call self.SetDisplayMode('fullwidth')
  "Disable compression
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
  let left = s:float(get(a:000, 0))
  let top = s:float(get(a:000, 1))
  let right = s:float(get(a:000, 2, s:null))
  "Set left, top and right margins
  let self.lMargin = left
  let self.tMargin = top
  if [right] == [s:null]
    let l:.right = left
  endif
  let self.rMargin = right
endfunction

function s:fpdf.SetLeftMargin(margin)
  let margin = s:float(a:margin)
  "Set left margin
  let self.lMargin = margin
  if self.page > 0 && self.x < margin
    let self.x = margin
  endif
endfunction

function s:fpdf.SetTopMargin(margin)
  "Set top margin
  let self.tMargin = s:float(a:margin)
endfunction

function s:fpdf.SetRightMargin(margin)
  "Set right margin
  let self.rMargin = s:float(s:margin)
endfunction

function s:fpdf.SetAutoPageBreak(...)
  let auto = get(a:000, 0)
  let margin = s:float(get(a:000, 1, 0))
  "Set auto page break mode and triggering margin
  let self.AutoPageBreak = auto
  let self.bMargin = margin
  let self.PageBreakTrigger = self.h - margin
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

function s:fpdf.SetTitle(title, ...)
  let isUTF8 = get(a:000, 0, s:false)
  "Title of document
  let self.title = a:title
endfunction

function s:fpdf.SetSubject(subject, ...)
  let isUTF8 = get(a:000, 0, s:false)
  "Subject of document
  let self.subject = a:subject
endfunction

function s:fpdf.SetAuthor(author, ...)
  let isUTF8 = get(a:000, 0, s:false)
  "Author of document
  let self.author = a:author
endfunction

function s:fpdf.SetKeywords(keywords, ...)
  let isUTF8 = get(a:000, 0, s:false)
  "Keywords of document
  let self.keywords = a:keywords
endfunction

function s:fpdf.SetCreator(creator, ...)
  let isUTF8 = get(a:000, 0, s:false)
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
  let format = get(a:000, 1, '')
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
  call self._beginpage(orientation, format)
  "Set line cap style to square
  call self._out('2 J')
  "Set line width
  let self.LineWidth = lw
  call self._out(printf('%.2F w', lw * self.k))
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
  let self.InHeader = s:true
  call self.Header()
  let self.InHeader = s:false
  "Restore line width
  if self.LineWidth != lw
    let self.LineWidth = lw
    call self._out(printf('%.2F w', lw * self.k))
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
  let r = s:float(get(a:000, 0))
  let g = s:float(get(a:000, 1, s:null))
  let b = s:float(get(a:000, 2, s:null))
  "Set color for all stroking operations
  if ([r] == [0] && [g] == [0] && [b] == [0]) || [g] == [s:null]
    let self.DrawColor = printf('%.3F G', r / 255.0)
  else
    let self.DrawColor = printf('%.3F %.3F %.3F RG', r / 255.0, g / 255.0, b / 255.0)
  endif
  if self.page > 0
    call self._out(self.DrawColor)
  endif
endfunction

function s:fpdf.SetFillColor(...)
  let r = s:float(get(a:000, 0))
  let g = s:float(get(a:000, 1, s:null))
  let b = s:float(get(a:000, 2, s:null))
  "Set color for all filling operations
  if ([r] == [0] && [g] == [0] && [b] == [0]) || [g] == [s:null]
    let self.FillColor = printf('%.3F g', r / 255.0)
  else
    let self.FillColor = printf('%.3F %.3F %.3F rg', r / 255.0, g / 255.0, b / 255.0)
  endif
  let self.ColorFlag = (self.FillColor != self.TextColor)
  if self.page > 0
    call self._out(self.FillColor)
  endif
endfunction

function s:fpdf.SetTextColor(...)
  let r = s:float(get(a:000, 0))
  let g = s:float(get(a:000, 1, s:null))
  let b = s:float(get(a:000, 2, s:null))
  "Set color for text
  if ([r] == [0] && [g] == [0] && [b] == [0]) || [g] == [s:null]
    let self.TextColor = printf('%.3F g', r / 255.0)
  else
    let self.TextColor = printf('%.3F %.3F %.3F rg', r / 255.0, g / 255.0, b / 255.0)
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
  return self.GetStringWidthPoint(a:s) * self.FontSize / 1000.0
endfunction

function s:fpdf.SetLineWidth(width)
  "Set line width
  let self.LineWidth = s:float(a:width)
  if self.page > 0
    call self._out(printf('%.2F w', a:width * self.k))
  endif
endfunction

function s:fpdf.Line(x1, y1, x2, y2)
  "Draw a line
  call self._out(printf('%.2F %.2F m %.2F %.2F l S', a:x1 * self.k, (self.h - a:y1) * self.k, a:x2 * self.k, (self.h - a:y2) * self.k))
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
  call self._out(printf('%.2F %.2F %.2F %.2F re %s', x * self.k, (self.h - y) * self.k, w * self.k, -h * self.k, op))
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
    return
  endif
  let g:fpdf#font = {}
  call s:include(self._getfontpath() . file)
  " fpdf#font should have type, name, desc, up, ut, cw, enc, file, diff
  if empty(g:fpdf#font)
    throw 'Could not include font definition file'
  endif
  let font = g:fpdf#font
  let i = len(self.fonts) + 1
  let font['i'] = i
  if font['type'] == 'core'
    let self.fonts[fontkey] = font
  elseif font['type'] == 'cidfont0'
    let self.fonts[family] = font
    let self.fonts[family.'B'] = extend({'name':font['name'].',Bold'}, font, 'keep')
    let self.fonts[family.'I'] = extend({'name':font['name'].',Italic'}, font, 'keep')
    let self.fonts[family.'BI'] = extend({'name':font['name'].',BoldItalic'}, font, 'keep')
  else
    let self.fonts[fontkey] = font
  endif
  let file = get(font, 'file', '')
  let diff = get(font, 'diff', 0)
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
    if font['type'] == 'TrueType'
      let self.FontFiles[file] = {'length1' : font['originalsize']}
    else
      let self.FontFiles[file] = {'length1' : size1, 'length2' : size2}
    endif
  endif
endfunction

function s:fpdf.SetFont(...)
  let family = get(a:000, 0)
  let style = get(a:000, 1, '')
  let size = s:float(get(a:000, 2, 0))

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
  if style =~ 'U'
    let self.underline = s:true
    let style = substitute(style, 'U', '', 'g')
  else
    let self.underline = s:false
  endif
  if style == 'IB'
    let style = 'BI'
  endif
  if size == 0
    let size = self.FontSizePt
  endif
  "Test if font is already selected
  if self.FontFamily == family && self.FontStyle == style && self.FontSizePt == size
    return
  endif
  "Test if used for the first time
  let fontkey = family . style
  if !has_key(self.fonts, fontkey)
    try
      try
        call self.AddFont(family, style)
      catch
        call self.AddFont(family, '')
        if !has_key(self.fonts, fontkey)
          throw "exception"
        endif
      endtry
    catch
      throw 'Undefined font: ' . family . ' ' . style
    endtry
  endif
  "Select it
  let self.FontFamily = family
  let self.FontStyle = style
  let self.FontSizePt = size
  let self.FontSize = size / self.k
  let self.CurrentFont = self.fonts[fontkey]
  if self.page > 0
    call self._out(printf('BT /F%d %.2F Tf ET', self.CurrentFont['i'], self.FontSizePt))
  endif
endfunction

function s:fpdf.SetFontSize(size)
  "Set font size in points
  if self.FontSizePt == a:size
    return
  endif
  let self.FontSizePt = s:float(a:size)
  let self.FontSize = a:size / self.k
  if self.page > 0
    call self._out(printf('BT /F%d %.2F Tf ET', self.CurrentFont['i'], self.FontSizePt))
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
  let y = s:float(get(a:000, 1, 0))
  let page = get(a:000, 2, -1)
  "Set destination of internal link
  if y == -1
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
  call add(self.PageLinks[self.page], [a:x * self.k, self.hPt - a:y * self.k, a:w * self.k, a:h * self.k, a:link])
endfunction

function s:fpdf.Text(x, y, txt)
  "Output a string
  let s = printf('BT %.2F %.2F Td %s Tj ET', a:x * self.k, (self.h - a:y) * self.k self._textstring(a:txt))
  if self.underline && a:txt != ''
    let s .= ' ' . self._dounderline(a:x, a:y, a:txt)
  endif
  if self.ColorFlag
    let s = 'q ' . self.TextColor . ' ' . s . ' Q'
  endif
  call self._out(s)
endfunction

function s:fpdf.AcceptPageBreak()
  "Accept automatic page break or not
  return self.AutoPageBreak
endfunction

function s:fpdf.Cell(...)
  let w = s:float(get(a:000, 0))
  let h = s:float(get(a:000, 1, 0))
  let txt = get(a:000, 2, '')
  let border = get(a:000, 3, 0)
  let ln = get(a:000, 4, 0)
  let align = get(a:000, 5, '')
  let fill = get(a:000, 6, s:false)
  let link = get(a:000, 7, '')

  "Output a cell
  let k = self.k
  if self.y + h > self.PageBreakTrigger && !self.InHeader && !self.InFooter && self.AcceptPageBreak()
    "Automatic page break
    let x = self.x
    let ws = self.ws
    if ws > 0
      let self.ws = s:float(0)
      call self._out('0 Tw')
    endif
    call self.AddPage(self.CurOrientation, self.CurPageFormat)
    let self.x = x
    if ws > 0
      let self.ws = ws
      call self._out(printf('%.3F Tw', ws * k))
    endif
  endif
  if w == 0
    let w = self.w - self.rMargin - self.x
  endif
  let s = ''
  if fill || border == 1
    if fill
      let op = (border==1) ? 'B' : 'f'
    else
      let op = 'S'
    endif
    let s = printf('%.2F %.2F %.2F %.2F re %s ', self.x * k, (self.h - self.y) * k, w * k, -h * k, op)
  endif
  if s:is_string(border)
    let x = self.x
    let y = self.y
    if border =~? 'L'
      let s .= printf('%.2F %.2F m %.2F %.2F l S ', x * k, (self.h - y) * k, x * k, (self.h - (y + h)) * k)
    endif
    if border =~? 'T'
      let s .= printf('%.2F %.2F m %.2F %.2F l S ', x * k, (self.h - y) * k, (x + w) * k, (self.h - y) * k)
    endif
    if border =~? 'R'
      let s .= printf('%.2F %.2F m %.2F %.2F l S ', (x + w) * k, (self.h - y) * k, (x + w) * k, (self.h - (y + h)) * k)
    endif
    if border =~? 'B'
      let s .= printf('%.2F %.2F m %.2F %.2F l S ', x * k, (self.h - (y + h)) * k, (x + w) * k, (self.h - (y + h)) * k)
    endif
  endif
  if txt != ''
    if align ==? 'R'
      let dx = w - self.cMargin - self.GetStringWidth(txt)
    elseif align ==? 'C'
      let dx = (w - self.GetStringWidth(txt)) / 2.0
    else
      let dx = self.cMargin
    endif
    if self.ColorFlag
      let s .= 'q ' . self.TextColor . ' '
    endif
    let s .= printf('BT %.2F %.2F Td %s Tj ET', (self.x + dx) * k, (self.h - (self.y + 0.5 * h + 0.3 * self.FontSize)) * k, self._textstring(txt))
    if self.underline
      let s .= ' ' . self._dounderline(self.x + dx, self.y + 0.5 * h + 0.3 * self.FontSize, txt)
    endif
    if self.ColorFlag
      let s .= ' Q'
    endif
    if link != ''
      call self.Link(self.x + dx, self.y + 0.5 * h - 0.5 * self.FontSize, self.GetStringWidth(txt), self.FontSize, link)
    endif
  endif
  if s != ''
    call self._out(s)
  endif
  let self.lasth = h
  if ln > 0
    "Go to next line
    let self.y = self.y + h
    if ln == 1
      let self.x = self.lMargin
    endif
  else
    let self.x = self.x + w
  endif
endfunction

function s:fpdf.MultiCell(...)
  let w = s:float(get(a:000, 0))
  let h = s:float(get(a:000, 1))
  let txt = get(a:000, 2)
  let border = get(a:000, 3, 0)
  let align = get(a:000, 4, 'J')
  let fill = get(a:000, 5, s:false)

  "Output text with automatic or explicit line breaks
  let cw = self.CurrentFont['cw']
  if w == 0
    let w = self.w - self.rMargin - self.x
  endif
  let wmax = (w - 2 * self.cMargin) * 1000.0 / self.FontSize
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
      if self.ws > 0
        let self.ws = 0.0
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
    if l > wmax
      "Automatic line break
      if sep == -1
        if i == j
          let i += 1
        endif
        if self.ws > 0
          let self.ws = 0.0
          call self._out('0 Tw')
        endif
        call self.Cell(w,h,s:mb_substr(s,j,i-j),b,2,align,fill)
      else
        if align ==? 'J'
          if ns > 1
            let self.ws = (wmax - ls) / 1000.0 * self.FontSize / (ns - 1)
          else
            let self.ws = 0.0
          endif
          call self._out(printf('%.3F Tw', self.ws * self.k))
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
  if self.ws > 0
    let self.ws = 0.0
    call self._out('0 Tw')
  endif
  if border =~? 'B'
    let b .= 'B'
  endif
  call self.Cell(w,h,s:mb_substr(s,j,i-j),b,2,align,fill)
  let self.x = self.lMargin
endfunction

function s:fpdf.Write(...)
  let h = s:float(get(a:000, 0))
  let txt = get(a:000, 1)
  let link = get(a:000, 2, '')
  let fill = get(a:000, 3, s:false)   " XXX: added

  "Output text in flowing mode
  let w = self.w - self.rMargin - self.x
  let wmax = (w - 2.0 * self.cMargin) * 1000.0 / self.FontSize
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
      call self.Cell(w, h, s:mb_substr(s, j, i-j), 0, 2, '', fill, link)
      let i += 1
      let sep = -1
      let j = i
      let l = 0
      if nl == 1
        let self.x = self.lMargin
        let w = self.w - self.rMargin - self.x
        let wmax = (w - 2.0 * self.cMargin) * 1000.0 / self.FontSize
      endif
      let nl += 1
      continue
    endif
    if c == ' '
      let sep = i
    endif
    let l += self.GetStringWidthPoint(c)
    if l > wmax
      "Automatic line break
      if sep == -1
        if self.x > self.lMargin
          "Move to next line
          let self.x = self.lMargin
          let self.y = self.y + h
          let w = self.w - self.rMargin - self.x
          let wmax = (w - 2.0 * self.cMargin) * 1000.0 / self.FontSize
          let i += 1
          let nl += 1
          continue
        endif
        if i == j
          let i += 1
        endif
        call self.Cell(w, h, s:mb_substr(s, j, i - j), 0, 2, '', fill, link)
      else
        call self.Cell(w, h, s:mb_substr(s, j, sep - j), 0, 2, '', fill, link)
        let i = sep + 1
      endif
      let sep = -1
      let j = i
      let l = 0
      if nl == 1
        let self.x = self.lMargin
        let w = self.w - self.rMargin - self.x
        let wmax = (w - 2.0 * self.cMargin) * 1000.0 / self.FontSize
      endif
      let nl += 1
    else
      let i += 1
    endif
  endwhile
  "Last chunk
  if i != j
    call self.Cell(l / 1000.0 * self.FontSize, h, s:mb_substr(s, j), 0, 0, '', fill, link)
  endif
endfunction

function s:fpdf.Ln(...)
  let h = get(a:000, 0, s:null)
  "Line feed; default value is last cell height
  let self.x = self.lMargin
  if [h] == [s:null]
    let self.y += self.lasth
  else
    let self.y += h
  endif
endfunction

function s:fpdf.Image(...)
  let file = get(a:000, 0)
  let x = s:float(get(a:000, 1, s:null))
  let y = s:float(get(a:000, 2, s:null))
  let w = s:float(get(a:000, 3, 0))
  let h = s:float(get(a:000, 4, 0))
  let type = get(a:000, 5, '')
  let link = get(a:000, 6, '')

  "Put an image on the page
  if !has_key(self.images, file)
    "First use of this image, get info
    if type == ''
      if file !~ '\.\w\+$'
        throw 'Image file has no extension and no type was specified: ' . file
      endif
      let type = matchstr(file, '\.\zs\w\+$')
    endif
    let type = tolower(type)
    if type == 'jpeg'
      let type = jpg'
    endif
    let mtd = '_parse'.type
    if !has_key(self, mtd)
      throw 'Unsupported image type: ' . type
    endif
    let info = self[mtd](file)
    let info['i'] = len(self.images) + 1
    let self.images[file] = info
  else
    let info = self.images[file]
  endif
  "Automatic width and height calculation if needed
  if w == 0 && h == 0
    "Put image at 72 dpi
    let w = info['w'] / self.k
    let h = info['h'] / self.k
  elseif w == 0
    let w = h * info['w'] / info['h']
  elseif h == 0
    let h = w * info['h'] / info['w']
  endif
  "Flowing mode
  if [y] == [s:null]
    if self.y + h > self.PageBreakTrigger && !self.InHeader && !self.InFooter && self.AcceptPageBreak()
      "Automatic page break
      let x2 = self.x
      call self.AddPage(self.CurOrientation, self.CurPageFormat)
      let self.x = x2
    endif
    let l:.y = self.y
    let self.y += h
  endif
  if [x] == [s:null]
    let l:.x = self.x
  endif
  call self._out(printf('q %.2F 0 0 %.2F %.2F %.2F cm /I%d Do Q', w * self.k, h * self.k, x * self.k, (self.h - (y + h)) * self.k, info['i']))
  if link
    call self.Link( x, y, w, h, link)
  endif
endfunction

function s:fpdf.GetX()
  "Get x position
  return self.x
endfunction

function s:fpdf.SetX(x)
  let x = s:float(a:x)
  "Set x position
  if x >= 0
    let self.x = x
  else
    let self.x = self.w + x
  endif
endfunction

function s:fpdf.GetY()
  "Get y position
  return self.y
endfunction

function s:fpdf.SetY(y)
  let y = s:float(a:y)
  "Set y position and reset x
  let self.x = self.lMargin
  if y >= 0
    let self.y = y
  else
    let self.y = self.h + a:y
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

function s:fpdf._dochecks()
endfunction

function s:fpdf._getpageformat(format)
  let format = tolower(a:format)
  if !has_key(self.PageFormats, format)
    throw 'Unknown page format: ' . format
  endif
  let a = self.PageFormats[format]
  return [a[0] / self.k, a[1] / self.k]
endfunction

function s:fpdf._getfontpath()
  if !exists('g:FPDF_FONTPATH') && isdirectory(s:dirname(s:__file__) . '/font')
    let g:FPDF_FONTPATH = s:dirname(s:__file__) . '/font/'
  endif
  return exists('g:FPDF_FONTPATH') ? g:FPDF_FONTPATH : ''
endfunction

function s:fpdf._beginpage(orientation, format)
  let orientation = a:orientation
  let format = a:format

  let self.page += 1
  let self.pages[self.page] = ''
  let self.state = 2
  let self.x = self.lMargin
  let self.y = self.tMargin
  let self.FontFamily = ''
  "Check page size
  if orientation == ''
    let orientation = self.DefOrientation
  else
    let orientation = toupper(orientation[0])
  endif
  if [format] == ['']
    let l:.format = self.DefPageFormat
  else
    if s:is_string(format)
      let l:.format = self._getpageformat(format)
    endif
  endif
  if orientation != self.CurOrientation || format[0] != self.CurPageFormat[0] || format[1] != self.CurPageFormat[1]
    "New size
    if orientation == 'P'
      let self.w = format[0]
      let self.h = format[1]
    else
      let self.w = format[1]
      let self.h = format[0]
    endif
    let self.wPt = self.w * self.k
    let self.hPt = self.h * self.k
    let self.PageBreakTrigger = self.h - self.bMargin
    let self.CurOrientation = orientation
    let self.CurPageFormat = format
  endif
  if orientation != self.DefOrientation || format[0] != self.DefPageFormat[0] || format[1] != self.DefPageFormat[1]
    let self.PageSizes[self.page] = [self.wPt, self.hPt]
  endif
endfunction

function s:fpdf._endpage()
  let self.state = 1
endfunction

function s:fpdf._escape(s)
  "Escape special characters in strings
  return escape(a:s, "\\()\r")
endfunction

function s:fpdf._escape_oct(s)
  return join(map(range(len(a:s)), 'char2nr(a:s[v:val]) <= 0x7F ? a:s[v:val] : printf(''\%03o'', char2nr(a:s[v:val]))'), '')
endfunction

function s:fpdf._textstring(s)
  "Format a text string
  let enc = get(self.CurrentFont, 'enc', '')
  if enc =~? 'utf-\?16'
    return '<' . self._bin2hex_utf16(a:s) . '>'
  elseif enc != '' && has('iconv')
    " TODO: which is best?
    " 1. ascii text, escaping non-ascii bytes
    " 2. hex encode
    return '(' . self._escape_oct(self._escape(iconv(a:s, &encoding, enc))) . ')'
    return '<' . self._bin2hex(iconv(a:s, &encoding, enc)) . '>'
  else
    return '(' . self._escape_oct(self._escape(a:s)) . ')'
  endif
endfunction

function s:fpdf._infostring(s)
  if a:s =~ '^[\x00-\x7F]*$'
    return '(' . self._escape(a:s) . ')'
  else
    return '<FEFF' . self._bin2hex_utf16(a:s) . '>'
  endif
endfunction

function s:fpdf._bin2hex(s)
  return join(map(range(len(a:s)), 'printf("%02X", char2nr(a:s[v:val]))'), '')
endfunction

function s:fpdf._bin2hex_utf16(s)
  return join(map(split(a:s, '\zs'), 'self._nr2utf16hex(char2nr(v:val))'), '')
endfunction

function s:fpdf._nr2utf16hex(char)
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

function s:fpdf._dounderline(x, y, txt)
  let [x, y, txt] = [a:x, a:y, a:txt]
  "Underline text
  let up = self.CurrentFont['up']
  let ut = self.CurrentFont['ut']
  let w = self.GetStringWidth(txt) + self.ws * s:substr_count(txt, ' ')
  return printf('%.2F %.2F %.2F %.2F re f', x * self.k, (self.h - (y - up / 1000.0 * self.FontSize)) * self.k, w * self.k, -ut / 1000.0 * self.FontSizePt)
endfunction

function s:fpdf._parsejpg(file)
  let file = a:file

  "Read whole file
  let data = self._readfilebin(file)
  "Extract info from a JPEG file
  let a = self._GetImageSizeJpeg(data)
  if a == {}
    throw 'Missing or incorrect image file: ' . file
  endif
  if a[2] != 2
    throw 'Not a JPEG file: ' . file
  endif
  if !has_key(a, 'channels') || a['channels'] == 3
    let colspace = 'DeviceRGB'
  elseif a['channels'] == 4
    let colspace = 'DeviceCMYK'
  else
    let colspace = 'DeviceGray'
  endif
  let bpc = get(a, 'bits', 8)
  let filter = '/Filter [/ASCIIHexDecode /DCTDecode]'
  return {'w' : a[0], 'h' : a[1], 'cs' : colspace, 'bpc' : bpc, 'f' : filter, 'data' : join(data, '')}
endfunction

function s:fpdf._GetImageSizeJpeg(data)
  " XXX: I don't know specification.
  let data = a:data
  let code = data[0] . data[1]
  if code !=? 'FFD8'
    throw 'GetImageSizeJpeg(): format error'
  endif
  let i = 2
  let code = data[i] . data[i + 1]
  while code !=? 'FFC0'
    let i += 2
    let size = self._readshort(data[i : i + 1])
    let i += size
    let code = data[i] . data[i + 1]
  endwhile
  if code !=? 'FFC0'
    throw 'GetImageSizeJpeg(): cannot get image size'
  endif
  let i += 2
  let data = data[i : i + 7]
  let lf = self._readshort(data)
  let p = self._readbyte(data)
  let y = self._readshort(data)
  let x = self._readshort(data)
  let nif = self._readbyte(data)
  let IMAGETYPE_JPEG = 2
  return {
        \ 0 : x,
        \ 1 : y,
        \ 2 : IMAGETYPE_JPEG,
        \ 3 : printf('width="%d" height="%d"', x, y),
        \ 'bits' : p,
        \ 'channels' : nif,
        \ 'mime' : 'image/jpeg',
        \ }
endfunction

function s:fpdf._parsepng(file)
  let file = a:file

  "Extract info from a PNG file
  let data = self._readfilebin(file)
  "Check signature
  "if(fread($f,8)!=chr(137).'PNG'.chr(13).chr(10).chr(26).chr(10))
  if self._readhex(data, 8) !=? '89504E470D0A1A0A'
    throw 'Not a PNG file: ' . file
  endif
  "Read header chunk
  call self._readhex(data, 4)
  if self._readstr(data, 4) !=? 'IHDR'
    throw 'Incorrect PNG file: ' . file
  endif
  let w = self._readint(data)
  let h = self._readint(data)
  let bpc = self._readbyte(data)
  if bpc > 8
    throw '16-bit depth not supported: ' . file
  endif
  let ct = self._readbyte(data)
  if ct == 0
    let colspace = 'DeviceGray'
  elseif ct == 2
    let colspace = 'DeviceRGB'
  elseif ct == 3
    let colspace = 'Indexed'
  else
    throw 'Alpha channel not supported: ' . file
  endif
  if self._readbyte(data) != 0
    throw 'Unknown compression method: ' . file
  endif
  if self._readbyte(data) != 0
    throw 'Unknown filter method: ' . file
  endif
  if self._readbyte(data) != 0
    throw 'Interlacing not supported: ' . file
  endif
  call self._readhex(data, 4)
  let filter = '/Filter [/ASCIIHexDecode /FlateDecode]'
  let parms = '/DecodeParms [null <</Predictor 15 /Colors ' . (ct==2 ? 3 : 1) . ' /BitsPerComponent ' . bpc . ' /Columns ' .  w . '>>]'
  "Scan chunks looking for palette, transparency and image data
  let pal = ''
  let trns = ''
  let block = []
  while 1
    let n = self._readint(data)
    let type = self._readstr(data, 4)
    if type == 'PLTE'
      "Read palette
      let pal = self._readhex(data, n)
      call self._readhex(data, 4)
    elseif type == 'tRNS'
      "Read transparency info
      let t = remove(data, 0, n - 1)
      if ct == 0
        let l:.trns = [str2nr(t[1], 16)]
      elseif ct == 2
        let l:.trns = [str2nr(t[1], 16), str2nr(t[3], 16), str2nr(t[5], 1)]
      else
        let pos = index(t, '00')
        if pos != -1
          let l:.trns = [pos]
        endif
      endif
      call self._readhex(data, 4)
    elseif type == 'IDAT'
      "Read image data block
      call add(block, self._readhex(data, n))
      call self._readhex(data, 4)
    elseif type == 'IEND'
      break
    else
      call self._readhex(data, n + 4)
    endif
    if n == 0
      break
    endif
  endwhile
  if colspace == 'Indexed' && pal == ''
    throw 'Missing palette in ' . file
  endif
  return {'w' : w, 'h' : h, 'cs' : colspace, 'bpc' : bpc, 'f' : filter, 'parms' : parms, 'pal' : pal, 'trns' : trns, 'data' : join(block, '')}
endfunction

function s:fpdf._readstr(data, n)
  let n = remove(a:data, 0, a:n - 1)
  call map(n, '"\\x" . v:val')
  return eval('"' . join(n, '') . '"')
endfunction

function s:fpdf._readhex(data, n)
  return join(remove(a:data, 0, a:n - 1), '')
endfunction

function s:fpdf._readint(data)
  "Read a 4-byte integer from file
  let n = get(a:000, 0, 1) ? remove(a:data, 0, 3) : reverse(remove(a:data, 0, 3))
  if str2nr(n[0], 16) >= 0x80
    throw '_readint(): overflow'
  endif
  call map(n, 'str2nr(v:val, 16)')
  return (n[0] * 0x1000000) + (n[1] * 0x10000) + (n[2] * 0x100) + n[3]
endfunction

function s:fpdf._readshort(data)
  let n = get(a:000, 0, 1) ? remove(a:data, 0, 1) : reverse(remove(a:data, 0, 1))
  call map(n, 'str2nr(v:val, 16)')
  return (n[0] * 0x100) + n[1]
endfunction

function s:fpdf._readbyte(data)
  return str2nr(remove(a:data, 0), 16)
endfunction

function s:fpdf._newobj()
  "Begin a new object
  let self.n += 1
  let self.offsets[self.n] = strlen(self.buffer)
  call self._out(self.n . ' 0 obj')
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

function s:fpdf._putpages()
  let nb = self.page
  if get(self, 'vAliasNbPages', '') != ''
    "Replace number of pages
    for n in range(1, nb)
      let self.pages[n] = substitute(self.pages[n], self.vAliasNbPages, nb, 'g')
    endfor
  endif
  if self.DefOrientation == 'P'
    let wPt = self.DefPageFormat[0] * self.k
    let hPt = self.DefPageFormat[1] * self.k
  else
    let wPt = self.DefPageFormat[1] * self.k
    let hPt = self.DefPageFormat[0] * self.k
  endif
  for n in range(1, nb)
    "Page
    call self._newobj()
    call self._out('<</Type /Page')
    call self._out('/Parent 1 0 R')
    if has_key(self.PageSizes, n)
      call self._out(printf('/MediaBox [0 0 %.2F %.2F]', self.PageSizes[n][0], self.PageSizes[n][1]))
    endif
    call self._out('/Resources 2 0 R')
    if has_key(self.PageLinks, n)
      "Links
      let annots = '/Annots ['
      for pl in self.PageLinks[n]
        let rect = printf('%.2F %.2F %.2F %.2F', pl[0], pl[1], pl[0] + pl[2], pl[1] - pl[3])
        let annots .= '<</Type /Annot /Subtype /Link /Rect [' . rect . '] /Border [0 0 0] '
        if s:is_string(pl[4])
          let annots .= '/A <</S /URI /URI ' . self._textstring(pl[4]) . '>>>>'
        else
          let l = self.links[pl[4]]
          let h = has_key(self.PageSizes, l[0]) ? self.PageSizes[l[0]][1] : hPt
          let annots .= printf('/Dest [%d 0 R /XYZ 0 %.2F null]>>', 1 + 2 * l[0], h - l[1] * self.k)
        endif
      endfor
      call self._out(annots . ']')
    endif
    call self._out('/Contents ' . (self.n + 1) . ' 0 R>>')
    call self._out('endobj')
    "Page content
    if self.compress
      let filter = '/Filter [/ASCIIHexDecode /FlateDecode] '
      let p = self._bin2hex(self.pages[n])
      let p = self._gzcompress(p)
    else
      let filter = ''
      let p = self.pages[n]
    endif
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
  call self._out(printf('/MediaBox [0 0 %.2F %.2F]', wPt, hPt))
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
  for [file, info] in items(self.FontFiles)
    "Font file embedding
    call self._newobj()
    let self.FontFiles[file]['n'] = self.n
    let fontdata = self._readfilebin(self._getfontpath() . file)
    let compressed = (file =~ '\.z$')
    if !compressed && has_key(info, 'length2')
      let header = (str2nr(fontdata[0], 16)==128)
      if header
        "Strip first binary header
        "let font = font[6 : ]
        call remove(fontdata, 0, 5)
      endif
      if header && str2nr(fontdata[info['length1']], 16) == 128
        "Strip second binary header
        "let font = font[0 : info['length1'] - 1] + font[info['length1'] + 6 : ]
        call remove(fontdata, info['length1'], info['length1'] + 5)
      endif
    endif
    let hex = join(fontdata, '')
    call self._out('<</Length ' . strlen(hex))
    if compressed
      call self._out('/Filter [/ASCIIHexDecode /FlateDecode]')
    else
      call self._out('/Filter /ASCIIHexDecode')
    endif
    call self._out('/Length1 ' . info['length1'])
    if has_key(info, 'length2')
      call self._out('/Length2 ' . info['length2'] . ' /Length3 0')
    endif
    call self._out('>>')
    call self._putstream(hex)
    call self._out('endobj')
  endfor
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
      if font['enc'] != ''
        if get(font, 'diff', 0) != 0
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
  for [file, info] in items(self.images)
    call self._newobj()
    let self.images[file]['n'] = self.n
    call self._out('<</Type /XObject')
    call self._out('/Subtype /Image')
    call self._out('/Width ' . info['w'])
    call self._out('/Height ' . info['h'])
    if info['cs'] == 'Indexed'
      let pallen = strlen(info['pal']) / 2    " count as byte
      call self._out('/ColorSpace [/Indexed /DeviceRGB ' . (pallen / 3 - 1) . ' ' . (self.n + 1) . ' 0 R]')
    else
      call self._out('/ColorSpace /' . info['cs'])
      if info['cs'] == 'DeviceCMYK'
        call self._out('/Decode [1 0 1 0 1 0 1 0]')
      endif
    endif
    call self._out('/BitsPerComponent ' . info['bpc'])
    if has_key(info, 'f')
      call self._out(info['f'])
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
      if self.compress
        let filter = '/Filter [/ASCIIHexDecode /FlateDecode] '
        let pal = self._gzcompress(info['pal'])
      else
        let filter = '/Filter /ASCIIHexDecode '
        let pal = info['pal']
      endif
      call self._newobj()
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
  call self._out('/Producer ' . self._infostring(printf('fpdf-vim %s (FPDF %s)', s:FPDF_VIM_VERSION, s:FPDF_VERSION)))
  if self.title != ''
    call self._out('/Title ' . self._infostring(self.title))
  endif
  if self.subject != ''
    call self._out('/Subject ' . self._infostring(self.subject))
  endif
  if self.author != ''
    call self._out('/Author ' . self._infostring(self.author))
  endif
  if self.keywords != ''
    call self._out('/Keywords ' . self._infostring(self.keywords))
  endif
  if self.creator != ''
    call self._out('/Creator ' . self._infostring(self.creator))
  endif
  call self._out('/CreationDate ' . self._infostring('D:' . strftime('%Y%m%d%H%M%S')))
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
    call self._out(printf('%010d 00000 n ', self.offsets[i]))
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

function s:fpdf._gzcompress(data)
  " data is hex dump string
  if !executable('xxd')
    throw 'cannot find xxd'
  elseif !executable('gzip')
    throw 'cannot find gzip'
  endif
  " convert RFC1952 (gzip) to RFC1950 (zlib)
  " TODO: this is probably wrong...
  let data = system('xxd -ps -r | gzip -c | xxd -ps -c 1', a:data)
  let data = self._parse_gzip_file(split(data))
  return '789c' . data
endfunction

function s:fpdf._parse_gzip_file(data)
  let data = a:data
  if self._readhex(data, 2) !=? '1F8B'
    throw 'Not a gzip file'
  endif
  let cm = self._readhex(data, 1)
  if cm !=? '08'
    throw 'not supported compression method : ' . cm
  endif
  let flg = self._readbyte(data)
  let mtime = self._readhex(data, 4)
  let xfl = self._readhex(data, 1)
  let os = self._readhex(data, 1)
  if self._getflg(flg, 2)     " FEXTRA
    let xlen = self._readshort(data, 0)
    call self._readhex(data, xlen)
  endif
  if self._getflg(flg, 3)     " FNAME
    while self._readhex(data, 1) != '00'
      " skip to zero-terminator
    endwhile
  endif
  if self._getflg(flg, 4)     " FCOMMENT
    while self._readhex(data, 1) != '00'
      " skip to zero-terminator
    endwhile
  endif
  if self._getflg(flg, 1)     " FHCRC
    let crc16 = self._readhex(data, 2)
  endif
  let body = self._readhex(data, len(data) - 8)
  let crc32 = self._readhex(data, 4)
  let isize = self._readhex(data, 4)
  return body
endfunction

function s:fpdf._getflg(bits, n)
  let s = 1
  for i in range(a:n)
    let s = s * 2
  endfor
  return (a:bits / s) % 1
endfunction

function s:fpdf._readfilebin(path)
  if !executable('xxd')
    throw 'cannot find xxd'
  elseif !filereadable(a:path)
    throw a:path . ' is not readable'
  endif
  let data = system('xxd -ps -c 1 ' . shellescape(a:path))
  return split(data)
endfunction






function s:fpdf._putcidfont0(font)
  let font = a:font

  if has_key(font, 'prebuild')
    let obj = substitute(font['prebuild'], '{\(.\{-}\)}', '\=eval(submatch(1))', 'g')
    call self._newobj()
    call self._out(obj)
    call self._out('endobj')
    return
  endif

  "Type0
  call self._newobj()
  call self._out('<</Type /Font')
  call self._out('/Subtype /Type0')
  call self._out('/BaseFont /' . font['name'] . '-' . font['cmap'])
  call self._out('/Encoding /' . font['cmap'])
  call self._out('/DescendantFonts [' . (self.n + 1) . ' 0 R]')
  call self._out('>>')
  call self._out('endobj')
  "CIDFont
  call self._newobj()
  call self._out('<</Type /Font')
  call self._out('/Subtype /CIDFontType0')
  call self._out('/BaseFont /' . font['name'])
  call self._out('/CIDSystemInfo ' . (self.n + 1) . ' 0 R')
  call self._out('/FontDescriptor ' . (self.n + 2) . ' 0 R')
  call self._out('/DW ' . font['dw'])
  call self._outfontwidths(font)
  call self._out('>>')
  call self._out('endobj')
  "CIDSystemInfo
  call self._newobj()
  call self._out('<</Registry (' . font['cidinfo']['Registry'] . ')')
  call self._out('/Ordering (' . font['cidinfo']['Ordering'] . ')')
  call self._out('/Supplement ' . font['cidinfo']['Supplement'])
  call self._out('>>')
  call self._out('endobj')
  "Font descriptor
  call self._newobj()
  call self._out('<</Type /FontDescriptor')
  call self._out(' /FontName /' . font['name'])
  for [k,v] in items(font['desc'])
    call self._out(' /' . k . ' ' . v)
  endfor
  call self._out('>>')
  call self._out('endobj')
endfunction

function s:fpdf._outfontwidths(font)
  let font = a:font
  " convert unicode to cid
  let uni2cid = get(font['cidinfo'], 'uni2cid', {})
  let cw = {}
  for uni in keys(font['cw'])
    if has_key(uni2cid, uni)
      let cid = uni2cid[uni]
      let cw[cid] = font['cw'][uni]
    elseif uni <= 255
      let cid = uni - 31
      let cw[cid] = font['cw'][uni]
    else
      " unknown character
    endif
  endfor
  " /W [
  "   <start> <end> <width> ...
  "   <start> [ <width of start> <width of start+2> ... ]
  " ]
  let cids = sort(keys(cw), 's:cmpnum')
  let ranges = [[cids[0], cids[0], cw[cids[0]]]] " [[start, end, width], ...]
  for cid in cids
    if cw[cid] != ranges[-1][2]
      call add(ranges, [cid, cid, cw[cid]])
    else
      let ranges[-1][1] = cid
    endif
  endfor
  " optimize
  let threshold = 4
  let i = 0
  while i + 1 < len(ranges)
    let j = i
    let [start1,end1,width1] = ranges[j]
    let [start2,end2,width2] = ranges[j + 1]
    while end1 - start1 <= threshold && end2 - start2 <= threshold && start2 - end1 <= threshold
      let j += 1
      if j + 1 >= len(ranges)
        break
      endif
      let [start1, end1, width1] = ranges[j]
      let [start2, end2, width2] = ranges[j + 1]
    endwhile
    if i != j
      let [start1, end1, width1] = ranges[i]
      let [start2, end2, width2] = ranges[j]
      call remove(ranges, i + 1, j)
      let widths = map(range(start1, end2), 'get(cw, v:val, 0)')
      let ranges[i] = [start1, start1, join(widths)]
    endif
    let i += 1
  endwhile
  call self._out('/W [')
  for [start,end,width] in ranges
    if start == end
      call self._out(printf(" %s [%s] ", start, width))
    else
      call self._out(printf(" %s %s %s ", start, end, width))
    endif
  endfor
  cal self._out(']')
endfunction

function! s:cmpnum(a, b)
  return a:a == a:b ? 0 : a:a > a:b ? 1 : -1
endfunction

