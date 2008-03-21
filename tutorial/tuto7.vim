let g:FPDF_FONTPATH = expand('<sfile>:p:h') . '/'

let FPDF = fpdf#import()

let pdf = FPDF.new()
call pdf.AddFont('Calligrapher','','calligra.vim')
call pdf.AddPage()
call pdf.SetFont('Calligrapher','',35)
call pdf.Cell(0,10,'Enjoy new fonts with FPDF!')
let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
