let g:fpdf_charwidths['courier'] = {}
for i in range(256)
  let g:fpdf_charwidths['courier'][i] = 600
endfor
let g:fpdf_charwidths['courierB'] = g:fpdf_charwidths['courier']
let g:fpdf_charwidths['courierI'] = g:fpdf_charwidths['courier']
let g:fpdf_charwidths['courierBI'] = g:fpdf_charwidths['courier']
