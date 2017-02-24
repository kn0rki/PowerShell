param($vms="*", $interval)
 Switch ($interval)
 {
 "day" {$days=-1;$mins=5;$divider=3000}
 "week" {$days=-7;$mins=30;$divider=18000}
 "month" {$days=-30;$mins=120;$divider=72000}
 }
 
$groups=Get-Stat -Entity (get-vm $vms ) -Stat cpu.ready.summation -start (get-date).adddays($days) -finish (get-date) -interval $mins -instance "" -ea silentlycontinue|group entity
 
$output=@()
 
ForEach ($group in $groups)
 {
 $temp= ""|select-Object Name, "Ready%"
 $temp.name=$group.name
 
$temp."ready%"= “{0:n2}” -f (($group.group |measure-object value -ave).average/$divider)
 
$output+=$temp
 }
 
$output