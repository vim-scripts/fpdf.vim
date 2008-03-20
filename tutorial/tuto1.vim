
let FPDF = fpdf#import()

let pdf = FPDF.new()
call pdf.AddPage()
call pdf.SetFont('Arial','B',16)
call pdf.Cell(40,10,'Hello World!')
let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
