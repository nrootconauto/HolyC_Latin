set words = ( ` tail -n+2 $argv[2] ` )
set idx = 0
set more2 = ( ` head -n1 $argv[2] ` )

set cases = ( NOMITIVE GENITIVE DATIVE ACCUSATIVE ABLATIVE VOCATIVE ) 
set numbers = ( SINGULAR PLURAL )
foreach w ( $words ) 
  @ c = $idx / 3  + 1
  @ n = (($idx % 3) == 2) + 1

  if ( $idx % 3  == 1 ) then
    set more = NEUTER 
  else if ( $idx % 3 == 2 ) then
    set more = 'MASCULINE|NEUTER|FEMININE'
  else
    set more = 'MASCULINE|FEMININE'
  endif
  @ idx = $idx + 1
  printf '\"%s\"\t%s|%s|%s|%s\t\"%s\"\n' $argv[1] "$more" "$cases[$c]" "$numbers[$n]" "$more2" $w
end
