if exists("b:current_syntax")
    finish
endif

syntax match fixComment "\v#.*$"
syntax keyword fixKeyword select reject
syntax keyword fixKeyword if else elsif unless bind do doset end and or
syntax keyword fixKeyword and or && ||
syntax match fix /[a-z][_0-9a-zA-Z]*\s*(/me=e-1,he=e-1
syntax region fixDoubleQuotedString start=/\v"/ skip=/\v\\./ end=/\v"/
syntax region fixSingleQuotedString start=/\v'/ skip=/\v\\./ end=/\v'/
syntax region fixIfBlock start="if" end="end" fold transparent

highlight default link fixComment Comment
highlight default link fixKeyword Keyword
highlight default link fix Function
highlight link fixDoubleQuotedString String
highlight link fixSingleQuotedString String

let b:current_syntax = "catmandu-fix"
