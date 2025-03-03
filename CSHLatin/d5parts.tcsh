set words = ( ` cat $argv[2] ` )
set idx = 0

set cases = ( NOMITIVE GENITIVE DATIVE ACCUSATIVE ABLATIVE VOCATIVE ) 
set numbers = ( SINGULAR PLURAL )
foreach w ( $words ) 
  @ c = $idx / 2  + 1
  @ n = $idx % 2 + 1
  @ idx = $idx + 1
  printf '\"%s\"\t%s|%s\t\"%s\"\n' $argv[1] "$cases[$c]" "$numbers[$n]" $w
end
