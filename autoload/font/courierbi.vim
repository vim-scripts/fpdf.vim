let g:fpdf#font = {}
let g:fpdf#font['type'] = 'core'
let g:fpdf#font['name'] = 'Courier-BoldOblique'
let g:fpdf#font['up'] = -100
let g:fpdf#font['ut'] = 50
let g:fpdf#font['cw'] = {}
for i in range(256)
  let g:fpdf#font['cw'][i] = 600
endfor
let g:fpdf#font['enc'] = 'cp1254'
