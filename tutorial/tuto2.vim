
let FPDF = fpdf#import()

" class PDF extends FPDF
let PDF = deepcopy(FPDF)

let s:file = expand("<sfile>:p")

function! PDF.Header()
  "Logo
  call self.Image(fnamemodify(s:file, ':h') . '/logo_pb.png',10,8,33)
  "Arial bold 15
  call self.SetFont('Arial','B',15)
  "Move to the right
  call self.Cell(80)
  "Title
  call self.Cell(30,10,'Title',1,0,'C')
  "Line break
  call self.Ln(20)
endfunction

function! PDF.Footer()
  "Position at 1.5 cm from bottom
  call self.SetY(-15)
  "Arial italic 8
  call self.SetFont('Arial','I',8)
  "Page number
  call self.Cell(0,10,'Page ' . self.PageNo() . '/{nb}',0,0,'C')
endfunction


"Instanciation of inherited class
let pdf = PDF.new()
call pdf.AliasNbPages()
call pdf.AddPage()
call pdf.SetFont('Times','',12)
for i in range(1, 40)
  call pdf.Cell(0,10,'Printing line number '.i,0,1)
endfor
let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
