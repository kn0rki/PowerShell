param
(
  [String]
  [Parameter(Mandatory=$true)]
  $Server
)

# Loading vmware powershell environment
& 'C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1' | Out-Null

$vcconnection =  Connect-VIServer $server -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if($vcconnection) {

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
}