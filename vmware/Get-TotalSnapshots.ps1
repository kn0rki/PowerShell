#requires -Version 2
param
(
    [String]
    [Parameter(Mandatory = $true)]
    $Server
)

# Loading vmware powershell environment
#& "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1" | Out-Null
if(Connect-VIServer $Server -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) 
{
    $TotalSnapshots = (Get-VM |
        Get-Snapshot |
        Where-Object -FilterScript {
            $_.Description -like '*VEEAM*'
    }).count
}

Disconnect-VIServer -Confirm:$false
exit $TotalSnapshots
