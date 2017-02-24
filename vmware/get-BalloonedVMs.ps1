$vms = get-vm
$myCol = @()
foreach($vm in ($vms | get-view | Where-Object {$_.Summary.QuickStats.BalloonedMemory -ne '0'})){
    $Details = '' | Select-Object VM, SwappedMemory ,BalloonedMemory
    $Details.VM = $vm.Name
    $Details.SwappedMemory = $vm.Summary.QuickStats.SwappedMemory
    $Details.BalloonedMemory = $vm.Summary.QuickStats.BalloonedMemory
    $myCol += $Details
}
Write-output $myCol
