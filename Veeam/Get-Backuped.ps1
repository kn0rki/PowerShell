# Get Backedup function
function Get-Backedup ($vm) {
    $val = $vm.CustomFields |Where-Object {$_.key -eq "VEEAM" } | Select-Object -Property Value
    $today = Get-Date -Format "MM/d/yyyy"
    $yesterday = get-date -format "MM/d/yyyy" -displayhint date ((get-date).adddays(-1))
    $backupDate = $val.Value
    if ( $backupDate -like "*$today*" -or $backupDate -like "*$yesterday*"  ) {
        $res = 1
    } else {
        $res = 0
    }
    return ( $res )
}
 
 
$vms = Get-VM
 
$resultok=@()
$resultnotok=@()
 
foreach ($vm in $vms) {
    if (Get-Backedup($vm)) {
        $resultok += "$vm `r`n"
    } else {
        $resultnotok += "$vm `r`n"
    }
}
 
$body += "==================================================`r`n`r`n"
$body += "The following VMs have NOT been backed up:`r`n"
$body += "---------------------------------------------------------------`r`n"
$body += $resultnotok | Sort-Object
$body += "`r`n`r`nThe following VMs have been backed up:`r`n"
$body += "--------------------------------------------------------`r`n"
$body += $resultok | Sort-Object
 

$body
$body | clip.exe