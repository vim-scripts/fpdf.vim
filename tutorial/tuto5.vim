
let FPDF = fpdf#import()

function s:array_sum(arr)
  return eval(join(a:arr, '+'))
endfunction

function s:number_format(num)
  let mx = '\d\zs\ze\d\{3}\%(,\|\_$\)'
  let s = a:num
  while s =~ mx
    let s = substitute(s, mx, ',', '')
  endwhile
  return s
endfunction

"class PDF extends FPDF
let PDF = deepcopy(FPDF)

"Load data
function PDF.LoadData(file)
  "Read file lines
  let lines = readfile(a:file)
  let data = []
  for line in lines
    call add(data, split(line, ';'))
  endfor
  return data
endfunction

"Simple table
function PDF.BasicTable(header,data)
  "Header
  for col in a:header
    call self.Cell(40,7,col,1)
  endfor
  call self.Ln()
  "Data
  for row in a:data
    for col in row
      call self.Cell(40,6,col,1)
    endfor
    call self.Ln()
  endfor
endfunction

"Better table
function PDF.ImprovedTable(header,data)
  "Column widths
  let w = [40,35,40,45]
  "Header
  for i in range(len(a:header))
    call self.Cell(w[i],7,a:header[i],1,0,'C')
  endfor
  call self.Ln()
  "Data
  for row in a:data
    call self.Cell(w[0],6,row[0],'LR')
    call self.Cell(w[1],6,row[1],'LR')
    call self.Cell(w[2],6,s:number_format(row[2]),'LR',0,'R')
    call self.Cell(w[3],6,s:number_format(row[3]),'LR',0,'R')
    call self.Ln()
  endfor
  "Closure line
  call self.Cell(s:array_sum(w),0,'','T')
endfunction

"Colored table
function PDF.FancyTable(header,data)
  "Colors, line width and bold font
  call self.SetFillColor(255,0,0)
  call self.SetTextColor(255)
  call self.SetDrawColor(128,0,0)
  call self.SetLineWidth('.3')
  call self.SetFont('','B')
  "Header
  let w = [40,35,40,45]
  for i in range(len(a:header))
    call self.Cell(w[i],7,a:header[i],1,0,'C',1)
  endfor
  call self.Ln()
  "Color and font restoration
  call self.SetFillColor(224,235,255)
  call self.SetTextColor(0)
  call self.SetFont('')
  "Data
  let fill = 0
  for row in a:data
    call self.Cell(w[0],6,row[0],'LR',0,'L',fill)
    call self.Cell(w[1],6,row[1],'LR',0,'L',fill)
    call self.Cell(w[2],6,s:number_format(row[2]),'LR',0,'R',fill)
    call self.Cell(w[3],6,s:number_format(row[3]),'LR',0,'R',fill)
    call self.Ln()
    let fill = !fill
  endfor
  call self.Cell(s:array_sum(w),0,'','T')
endfunction

let pdf = PDF.new()
"Column titles
let header = ['Country','Capital','Area (sq km)','Pop. (thousands)']
"Data loading
let data = pdf.LoadData(expand("<sfile>:p:h") . '/countries.txt')
call pdf.SetFont('Arial','',14)
call pdf.AddPage()
call pdf.BasicTable(header,data)
call pdf.AddPage()
call pdf.ImprovedTable(header,data)
call pdf.AddPage()
call pdf.FancyTable(header,data)
let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
