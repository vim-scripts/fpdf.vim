let g:fpdf#font = {}
let g:fpdf#font['type'] = 'cidfont0'
let g:fpdf#font['name'] = 'MS-Mincho'
let g:fpdf#font['desc'] = {'Ascent' : 859, 'Descent' : -141, 'CapHeight' : 27, 'Flags' : 32, 'FontBBox' : '[-82 -137 996 859]', 'ItalicAngle' : 0, 'StemV' : 70, 'MissingWidth' : 600}
let g:fpdf#font['up'] = -94
let g:fpdf#font['ut'] = 47
let g:fpdf#font['dw'] = 1000
let g:fpdf#font['cw'] = {
      \ 32:500  ,33:500  ,34:500  ,35:500  ,36:500  ,37:500  ,38:500  ,
      \ 39:500  ,40:500  ,41:500  ,42:500  ,43:500  ,44:500  ,45:500  ,
      \ 46:500  ,47:500  ,48:500  ,49:500  ,50:500  ,51:500  ,52:500  ,
      \ 53:500  ,54:500  ,55:500  ,56:500  ,57:500  ,58:500  ,59:500  ,
      \ 60:500  ,61:500  ,62:500  ,63:500  ,64:500  ,65:500  ,66:500  ,
      \ 67:500  ,68:500  ,69:500  ,70:500  ,71:500  ,72:500  ,73:500  ,
      \ 74:500  ,75:500  ,76:500  ,77:500  ,78:500  ,79:500  ,80:500  ,
      \ 81:500  ,82:500  ,83:500  ,84:500  ,85:500  ,86:500  ,87:500  ,
      \ 88:500  ,89:500  ,90:500  ,91:500  ,92:500  ,93:500  ,94:500  ,
      \ 95:500  ,96:500  ,97:500  ,98:500  ,99:500  ,100:500  ,101:500  ,
      \ 102:500  ,103:500  ,104:500  ,105:500  ,106:500  ,107:500  ,108:500  ,
      \ 109:500  ,110:500  ,111:500  ,112:500  ,113:500  ,114:500  ,115:500  ,
      \ 116:500  ,117:500  ,118:500  ,119:500  ,120:500  ,121:500  ,122:500  ,
      \ 123:500  ,124:500  ,125:500  ,126:500,
      \ }
let g:fpdf#font['enc'] = 'UniJIS-UTF16-H'
let g:fpdf#font['cidinfo'] = {'Registry' : 'Adobe', 'Ordering' : 'Japan1', 'Supplement' : 5}
" not required when prebuild is defined
"so <sfile>:p:h/uni2cid_aj16.vim
let g:fpdf#font['file'] = ''
let g:fpdf#font['diff'] = ''

let s:lines = readfile(expand('<sfile>'))
call remove(s:lines, 0, index(s:lines, 'finish'))
let g:fpdf#font['prebuild'] = join(s:lines, "\n")
unlet s:lines

finish
<<
  /Type /Font
  /Subtype /Type0
  /BaseFont /{font['name'] . '-' . font['enc']}
  /Encoding /UniJIS-UTF16-H
  /DescendantFonts
  [<<
    /Type /Font
    /Subtype /CIDFontType0
    /BaseFont /{font['name']}
    /CIDSystemInfo
    <<
      /Registry (Adobe)
      /Ordering (Japan1)
      /Supplement 5
    >>
    /FontDescriptor
    <<
      /Type /FontDescriptor
      /FontName /{font['name']}
      /Flags 32
      /FontBBox [-82 -137 996 859]
      /Ascent 859
      /MissingWidth 600
      /ItalicAngle 0
      /StemV 70
      /CapHeight 27
      /Descent -141
    >>
    /DW 1000
    /W [1 100 500]
  >>]
>>
