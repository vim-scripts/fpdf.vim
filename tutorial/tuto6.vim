
let FPDF = fpdf#import()
let s:float = float#import()

"class PDF extends FPDF
let PDF = deepcopy(FPDF)
let PDF.FPDF = FPDF

let PDF.B = 0
let PDF.I = 0
let PDF.U = 0
let PDF.HREF = ''

function! PDF.__construct()
  let orientation = get(a:000, 0, 'P')
  let unit = get(a:000, 1, 'mm')
  let format = get(a:000, 2, 'A4')
  "Call parent constructor
  call call(self.FPDF.__construct, [orientation, unit, format], self)
  "Initialization
  let self.B = 0
  let self.I = 0
  let self.U = 0
  let self.HREF = ''
endfunction

function! s:split_delim_capture(s, mx)
  " BOGUS:
  let lst = []
  let e = 0
  let i = match(a:s, a:mx)
  while i != -1
    call add(lst, strpart(a:s, e, i - e))
    let _ = matchlist(a:s, a:mx, i)
    call add(lst, _[1])
    let e = matchend(a:s, a:mx, i)
    let i = match(a:s, a:mx, e)
  endwhile
  call add(lst, strpart(a:s, e))
  return lst
endfunction

function PDF.WriteHTML(html)
  "HTML parser
  let html = substitute(a:html, "\n", " ", "g")
  let a = s:split_delim_capture(html, '<\(.\{-}\)>')
  for i in range(len(a))
    let e = a[i]
    if i % 2 == 0
      "Text
      if self.HREF != ''
        call self.PutLink(self.HREF,e)
      else
        call self.Write(5,e)
      endif
    else
      "Tag
      if e[0] == '/'
        call self.CloseTag(toupper(e[1:]))
      else
        "Extract attributes
        let [tag; a2] = split(e, ' ')
        let attr = {}
        for v in a2
          let a3 = matchlist(v, '^\([^=]*\)=["'']\?\([^"'']*\)["'']\?$')
          if a3 != []
            let attr[toupper(a3[1])] = a3[2]
          endif
        endfor
        call self.OpenTag(tag,attr)
      endif
    endif
  endfor
endfunction

function PDF.OpenTag(tag,attr)
  "Opening tag
  if a:tag=='B' || a:tag=='I' || a:tag=='U'
    call self.SetStyle(a:tag,1)
  endif
  if a:tag=='A'
    let self.HREF = a:attr['HREF']
  endif
  if a:tag == 'BR'
    call self.Ln(5)
  endif
endfunction

function PDF.CloseTag(tag)
  "Closing tag
  if a:tag=='B' || a:tag=='I' || a:tag=='U'
    call self.SetStyle(a:tag,0)
  endif
  if a:tag=='A'
    let self.HREF=''
  endif
endfunction

function PDF.SetStyle(tag,enable)
  "Modify style and select corresponding font
  let self[a:tag] += (a:enable ? 1 : -1)
  let style = ''
  for s in ['B', 'I', 'U']
    if self[s] > 0
      let style .= s
    endif
  endfor
  call self.SetFont('',style)
endfunction

function PDF.PutLink(URL,txt)
  "Put a hyperlink
  call self.SetTextColor(0,0,255)
  call self.SetStyle('U',1)
  call self.Write(5,a:txt,a:URL)
  call self.SetStyle('U',0)
  call self.SetTextColor(0)
endfunction

let html = ''
      \ . "You can now easily print text mixing different\n"
      \ . "styles : <B>bold</B>, <I>italic</I>, <U>underlined</U>, or\n"
      \ . "<B><I><U>all at once</U></I></B>!<BR>You can also insert links\n"
      \ . "on text, such as <A HREF=\"http://www.fpdf.org\">www.fpdf.org</A>,\n"
      \ . "or on an image: click on the logo.\n"

let pdf = PDF.new()
"First page
call pdf.AddPage()
call pdf.SetFont('Arial','',20)
call pdf.Write(5,"To find out what's new in this tutorial, click ")
call pdf.SetFont('','U')
let link = pdf.AddLink()
call pdf.Write(5,'here',link)
call pdf.SetFont('')
"Second page
call pdf.AddPage()
call pdf.SetLink(link)
"Image not implemented
"call pdf.Image('logo.png',10,10,30,0,'','http://www.fpdf.org')
call pdf.SetLeftMargin(45)
call pdf.SetFontSize(14)
call pdf.WriteHTML(html)
let pdfout = pdf.Output()

new
put =pdfout
1delete _
set ft=pdf
