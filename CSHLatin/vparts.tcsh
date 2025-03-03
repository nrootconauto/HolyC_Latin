set words = ( ` tail +2 $argv[2] | cut -f2,4 ` )
set idx = 0
set more = ''
set more2 = ` head -n1 $argv[2] `

foreach w ( $words ) 
  set base = ` echo $argv[3] |wc -c  `
  set trimmed = ` echo $w | cut -c$base- `
  if ( $idx == 0 ) then 
    set more = "SINGULAR|_1P|"
  endif
  if ( $idx == 1) then
    set more = "PLURAL|_1P|"
  endif
  if ( $idx == 2) then
    set more = "SINGULAR|_2P|"
  endif
  if ( $idx == 3) then
    set more = "PLURAL|_2P|"
  endif
  if ( $idx == 4) then
    set more = "SINGULAR|_3P|"
  endif
  if ( $idx == 5) then
    set more = "PLURAL|_3P|"
  endif
  @ idx = $idx + 1
  printf '\"%s\"\t%s\t\"%s\"\n' $argv[1] $more$more2 $trimmed
end
