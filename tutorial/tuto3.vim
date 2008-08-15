
let FPDF = fpdf#import()

"class PDF extends FPDF
let PDF = deepcopy(FPDF)

function! PDF.Header()
  "Arial bold 15
  call self.SetFont('Arial','B',15)
  "Calculate width of title and position
  let w = self.GetStringWidth(g:title) + 6
  call self.SetX((210.0 - w) / 2.0)
  "Colors of frame, background and text
  call self.SetDrawColor(0,80,180)
  call self.SetFillColor(230,230,0)
  call self.SetTextColor(220,50,50)
  "Thickness of frame (1 mm)
  call self.SetLineWidth(1)
  "Title
  call self.Cell(w,9,g:title,1,1,'C',1)
  "Line break
  call self.Ln(10)
endfunction

function! PDF.Footer()
  "Position at 1.5 cm from bottom
  call self.SetY(-15)
  "Arial italic 8
  call self.SetFont('Arial','I',8)
  "Text color in gray
  call self.SetTextColor(128)
  "Page number
  call self.Cell(0,10,'Page ' . self.PageNo(),0,0,'C')
endfunction

function PDF.ChapterTitle(num,label)
  "Arial 12
  call self.SetFont('Arial','',12)
  "Background color
  call self.SetFillColor(200,220,255)
  "Title
  call self.Cell(0,6,printf("Chapter %s : %s", a:num, a:label),0,1,'L',1)
  "Line break
  call self.Ln(4)
endfunction

function PDF.ChapterBody(file)
  "Read text file
  let txt = iconv(join(readfile(a:file), "\n"), 'latin1', &enc)
  "Times 12
  call self.SetFont('Times','',12)
  "Output justified text
  call self.MultiCell(0,5,txt)
  "Line break
  call self.Ln()
  "Mention in italics
  call self.SetFont('','I')
  call self.Cell(0,5,'(end of excerpt)')
endfunction

function PDF.PrintChapter(num,title,file)
  call self.AddPage()
  call self.ChapterTitle(a:num,a:title)
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
