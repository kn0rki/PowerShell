$VMs = get-vm
$VMs | Get-Snapshot | Where-Object -FilterScript { $_.Description -like '*VEEAM*' }

