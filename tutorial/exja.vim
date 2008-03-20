
" require :set enc=utf-8 for CJK text

scriptencoding utf-8

let fpdf = fpdf#import()

let pdf = fpdf.new()

" AddMBFont(family, cmap)
" family: You can use any font name which PDF viewer know.
" cmap:
"   UniCNS : Chinese (Simplified)
"   UniGB  : Chinese (Traditional)
"   UniKS  : Korean
"   UniJIS : Japanese
call pdf.AddMBFont('MS-Gothic', 'UniJIS')

call pdf.AddPage()
call pdf.SetFont('Arial','B',16)
call pdf.SetTextColor(255, 0, 0)
call pdf.Write(10,"Hello World!\n")

call pdf.SetFont('MS-Gothic')
call pdf.SetTextColor(0, 255, 0)
call pdf.Write(10,"こんにちは世界\n")
call pdf.Write(10,"雨ニモマケズ\n")
call pdf.Write(10,"風ニモマケズ\n")

let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
