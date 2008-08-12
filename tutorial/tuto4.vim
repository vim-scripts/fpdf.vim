
let FPDF = fpdf#import()

"class PDF extends FPDF
let PDF = deepcopy(FPDF)

"Current column
let PDF.col = 0
"Ordinate of column start
let PDF.y0 = 0.0

function! PDF.Header()
  "Page header
  call self.SetFont('Arial','B',15)
  let w = self.GetStringWidth(g:title) + 6
  call self.SetX((210.0 - w) / 2.0)
  call self.SetDrawColor(0,80,180)
  call self.SetFillColor(230,230,0)
  call self.SetTextColor(220,50,50)
  call self.SetLineWidth(1)
  call self.Cell(w,9,g:title,1,1,'C',1)
  call self.Ln(10)
  "Save ordinate
  let self.y0 = self.GetY()
endfunction

function! PDF.Footer()
  "Page footer
  call self.SetY(-15)
  call self.SetFont('Arial','I',8)
  call self.SetTextColor(128)
  call self.Cell(0,10,'Page ' . self.PageNo(),0,0,'C')
endfunction

function PDF.SetCol(col)
  "Set position at a given column
  let self.col = a:col
  let x = 10 + a:col * 65
  call self.SetLeftMargin(x)
  call self.SetX(x)
endfunction

function! PDF.AcceptPageBreak()
  "Method accepting or not automatic page break
  if self.col < 2
    "Go to next column
    call self.SetCol(self.col + 1)
    "Set ordinate to top
    call self.SetY(self.y0)
    "Keep on page
    return 0
  else
    "Go back to first column
    call self.SetCol(0)
    "Page break
    return 1
  endif
endfunction

function PDF.ChapterTitle(num,label)
  "Title
  call self.SetFont('Arial','',12)
  call self.SetFillColor(200,220,255)
  call self.Cell(0,6, printf("Chapter %s : %s", a:num, a:label),0,1,'L',1)
  call self.Ln(4)
  "Save ordinate
  let self.y0 = self.GetY()
endfunction

function PDF.ChapterBody(file)
  "Read text file
  let txt = join(readfile(a:file), '')
  "Font
  call self.SetFont('Times','',12)
  "Output text in a 6 cm width column
  call self.MultiCell(60,5,txt)
  call self.Ln()
  "Mention
  call self.SetFont('','I')
  call self.Cell(0,5,'(end of excerpt)')
  "Go back to first column
  call self.SetCol(0)
endfunction

function PDF.PrintChapter(num,title,file)
  "Add chapter
  call self.AddPage()
  call self.ChapterTitle(a:num, a:title)
  call self.ChapterBody(a:file)
endfunction

echo "Please wait ..."

let pdf = PDF.new()
let g:title = '20000 Leagues Under the Seas'
call pdf.SetTitle(g:title)
call pdf.SetAuthor('Jules Verne')
call pdf.PrintChapter(1,'A RUNAWAY REEF', expand("<sfile>:p:h") . '/20k_c1.txt')
call pdf.PrintChapter(2,'THE PROS AND CONS', expand("<sfile>:p:h") . '/20k_c2.txt')
let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
