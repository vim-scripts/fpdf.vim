
if !&cp && !exists(":TOpdf") && has("user_commands")
  command -range=% TOpdf :call Convert2PDF(<line1>, <line2>)

  func Convert2PDF(line1, line2)
    if a:line2 >= a:line1
      let g:html_start_line = a:line1
      let g:html_end_line = a:line2
    else
      let g:html_start_line = a:line2
      let g:html_end_line = a:line1
    endif

    runtime syntax/2pdf.vim

    unlet g:html_start_line
    unlet g:html_end_line
  endfunc

endif

