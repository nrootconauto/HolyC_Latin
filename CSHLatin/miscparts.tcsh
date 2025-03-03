set words = ( ` cat $argv[1] ` )
set idx = 1
set trim = ` echo $argv[2] | wc -c `
while ( $idx < $#words )
  set class = $words[$idx]
  @ idx++
  set flags = $words[$idx]
  @ idx++
  set word = ` echo $words[$idx] | cut -c$trim- ` 
  @ idx++
  printf '%s\t%s\t\"%s\"\n' $class $flags $word
end
