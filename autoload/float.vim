" License: This file is placed in the public domain.

function float#import()
  return s:float
endfunction

let s:float = {}
let s:float.class = s:float
" self.k should be multiples of 10
let s:float.k = 100

function s:float.new(v)
  let new = copy(self)
  if self.is_float(a:v)
    let new.val = a:v.val
  elseif type(a:v) == type(0)
    let new.val = a:v * self.k
  elseif type(a:v) == type('')
    if a:v =~ '\.'
      let [i, f] = split(a:v, '\.', 1)
      let i = (i + 0) * self.k
      let sk = string(self.k)
      while len(f) < len(sk) - 1
        let f = f . '0'
      endwhile
      while len(f) > len(sk) - 1
        let f = strpart(f, 0, len(f) - 1)
      endwhile
      let new.val = i + (f + 0)
    else
      let new.val = (a:v + 0) * self.k
    endif
  else
    throw 'float.new: type error'
  endif
  let new.add = self.unadd
  let new.sub = self.unsub
  let new.mul = self.unmul
  let new.div = self.undiv
  let new.cmp = self.uncmp
  unlet new.unadd
  unlet new.unsub
  unlet new.unmul
  unlet new.undiv
  unlet new.uncmp
  return new
endfunction

function s:float.cast(a)
  return self.is_float(a:a) ? a:a : self.new(a:a)
endfunction

function s:float.is_float(v)
  return (type(a:v) == type({}) && has_key(a:v, 'class') && a:v['class'] is s:float)
endfunction

function s:float.add(a, b)
  return self.new(a:a).add(self.cast(a:b))
endfunction

function s:float.sub(a, b)
  return self.new(a:a).sub(self.cast(a:b))
endfunction

function s:float.mul(a, b)
  return self.new(a:a).mul(self.cast(a:b))
endfunction

function s:float.div(a, b)
  return self.new(a:a).div(self.cast(a:b))
endfunction

function s:float.cmp(a, b)
  return self.cast(a:a).cmp(self.cast(a:b))
endfunction

function s:float.tostr(...)
  " TODO: fmt
  let fmt = get(a:000, 0, '')
  let i = self.val / self.k
  let f = string(self.val % self.k)
  let sk = string(self.k)
  while len(f) < len(sk) - 1
    let f = '0' . f
  endwhile
  let f = substitute(f, '-\|0*$', '', 'g')
  if f == 0
    return string(i)
  endif
  return printf("%d.%s", i, f)
endfunction

function s:float.unadd(b)
  let self.val += self.cast(a:b).val
  return self
endfunction

function s:float.unsub(b)
  let self.val -= self.cast(a:b).val
  return self
endfunction

function s:sign(v)
  return (a:v >= 0) ? 1 : -1
endfunction

function s:float.unmul(b)
  let b = self.cast(a:b).val
  let val = self.val * b / self.k
  if s:sign(self.val) * s:sign(b) != s:sign(val)
    throw 'float.unmul(): overflow error'
  endif
  let self.val = val
  return self
endfunction

function s:float.undiv(b)
  let b = self.cast(a:b).val
  let val = self.k * self.val / b
  if s:sign(self.val) * s:sign(b) != s:sign(val)
    throw 'float.undiv(): overflow error'
  endif
  let self.val = val
  return self
endfunction

function s:float.uncmp(b)
  let a = self.val
  let b = self.cast(a:b).val
  return (a < b) ? -1 : (b < a) ? 1 : 0
endfunction

