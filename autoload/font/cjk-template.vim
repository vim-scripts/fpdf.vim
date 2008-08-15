" This file is template for CJK cidfont.

let g:fpdf#font = {}

let g:fpdf#font['type'] = 'cidfont0'

" You can use any font name which PDF viewer know.
let g:fpdf#font['name'] = 'MS-PMincho'

" you can get actual information with
" fpdf/font/makefont/makefont.php or tcpdf/fonts/utils/makefont.php
" http://www.fpdf.org/
" http://www.tecnick.com/public/code/cp_dpage.php?aiocp_dp=tcpdf

let g:fpdf#font['desc'] = {'Ascent' : 859, 'Descent' : -141, 'CapHeight' : 27, 'Flags' : 32, 'FontBBox' : '[-82 -137 996 859]', 'ItalicAngle' : 0, 'StemV' : 70, 'MissingWidth' : 600}

let g:fpdf#font['up'] = -94
let g:fpdf#font['ut'] = 47
" default character width
let g:fpdf#font['dw'] = 1000
" character width (unicode=>width)
" This is for monospace.
" When using monospace font, you don't need to add all characters.
let g:fpdf#font['cw'] = {32:500,33:500,34:500,35:500,36:500,37:500,38:500,39:500,40:500,41:500,42:500,43:500,44:500,45:500,46:500,47:500,48:500,49:500,50:500,51:500,52:500,53:500,54:500,55:500,56:500,57:500,58:500,59:500,60:500,61:500,62:500,63:500,64:500,65:500,66:500,67:500,68:500,69:500,70:500,71:500,72:500,73:500,74:500,75:500,76:500,77:500,78:500,79:500,80:500,81:500,82:500,83:500,84:500,85:500,86:500,87:500,88:500,89:500,90:500,91:500,92:500,93:500,94:500,95:500,96:500,97:500,98:500,99:500,100:500,101:500,102:500,103:500,104:500,105:500,106:500,107:500,108:500,109:500,110:500,111:500,112:500,113:500,114:500,115:500,116:500,117:500,118:500,119:500,120:500,121:500,122:500,123:500,124:500,125:500,126:500}

" CID Information
" Select your language
" unicode to cid conversion table is from
" ftp://ftp.oreilly.com/pub/examples/nutshell/cjkv/adobe/
" cid2code.txt in ac16.tar.Z, ag15.tar.Z, ak12.tar.Z and aj16.tar.Z.

"let g:fpdf#font['enc'] = 'utf-16'
"let g:fpdf#font['cmap'] = 'UniCNS-UTF16-H'
"let g:fpdf#font['cidinfo'] = {'Registry' : 'Adobe', 'Ordering' : 'CNS1', 'Supplement' : 0}
"so <sfile>:p:h/uni2cid_ac16.vim

"let g:fpdf#font['enc'] = 'utf-16'
"let g:fpdf#font['cmap'] = 'UniGB-UTF16-H'
"let g:fpdf#font['cidinfo'] = {'Registry' : 'Adobe', 'Ordering' : 'GB1', 'Supplement' : 2}
"so <sfile>:p:h/uni2cid_ag15.vim

"let g:fpdf#font['enc'] = 'utf-16'
"let g:fpdf#font['cmap'] = 'UniKS-UTF16-H'
"let g:fpdf#font['cidinfo'] = {'Registry' : 'Adobe', 'Ordering' : 'Korea1', 'Supplement' : 0}
"so <sfile>:p:h/uni2cid_ak12.vim

"let g:fpdf#font['enc'] = 'utf-16'
"let g:fpdf#font['cmap'] = 'UniJIS-UTF16-H'
"let g:fpdf#font['cidinfo'] = {'Registry' : 'Adobe', 'Ordering' : 'Japan1', 'Supplement' : 6}
"so <sfile>:p:h/uni2cid_aj16.vim

let g:fpdf#font['file'] = ''
let g:fpdf#font['diff'] = ''
