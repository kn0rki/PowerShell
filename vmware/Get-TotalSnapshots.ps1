param(
  [String]
  [Parameter(Mandatory=$true)]
  $Server
)

# Loading vmware powershell environment
& 'C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1' | Out-Null

$vcconnection =  Connect-VIServer $server -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if($vcconnection) {
	$TotalSnapshots = (Get-VM | Get-Snapshot | Where-Object {$_.Description -like '*VEEAM*'}).count
    Disconnect-VIServer -Confirm:$false
} else {
    Write-Output 'no connection established'
}

