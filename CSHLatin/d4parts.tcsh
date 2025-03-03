set words = ( ` cat $argv[2] ` )
set idx = 0

set cases = ( NOMITIVE GENITIVE DATIVE ACCUSATIVE ABLATIVE VOCATIVE ) 
set numbers = ( SINGULAR PLURAL )
foreach w ( $words ) 
  @ c = $idx / 4 % 6 + 1
  @ n = $idx % 2 + 1

  if ( $idx / 2 % 2  == 1 ) then
    set more = NEUTER 
  else
    set more = 'MASCULINE|FEMININE'
  endif
  @ idx = $idx + 1
  printf '\"%s\"\t%s|%s|%s\t\"%s\"\n' $argv[1] "$more" "$cases[$c]" "$numbers[$n]" $w
end
