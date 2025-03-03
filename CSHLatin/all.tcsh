set sets = ( ` ls 1*.txt ` )
foreach s ( $sets )
  tcsh vparts.tcsh 1v $s am
end
set sets = ( ` ls 2*.txt ` )
foreach s ( $sets )
  tcsh vparts.tcsh 2v $s mon
end
set sets = ( ` ls 3*.txt ` )
foreach s ( $sets )
  tcsh vparts.tcsh 3v $s teg
end
set sets = ( ` ls 4*.txt ` )
foreach s ( $sets )
  tcsh vparts.tcsh 4v $s audi
end
tcsh d1parts.tcsh d1n d1n.txt ''
tcsh d1parts.tcsh d1a d1a.txt ''
tcsh d2parts.tcsh d2 d2.txt ''
tcsh d3parts.tcsh d3 d3.txt ''
tcsh d4parts.tcsh d4 d4.txt ''
tcsh d5parts.tcsh d5 d5.txt ''
