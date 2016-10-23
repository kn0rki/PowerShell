#requires -Version 1
#Defrag all Vmware Workstation VMDK Files via vmware-vdiskmanager.exe


param(
    [string]$vmdkpath = '.\',
    [string]$vmwarevdiskmanagerpath
)

if(!($vmwarevdiskmanagerpath))
{
    $vmwarevdiskmanagerpath = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation\').installpath
    $vmwarevdiskmanagerpath += 'vmware-vdiskmanager.exe'
}


$files = Get-ChildItem -Path $vmdkpath -Recurse |
    Where-Object -FilterScript {
        $_.Name -like '*.vmdk'
    } |
        ForEach-Object -Process {
            Write-Output -InputObject $_.VersionInfo.Filename
        }

$files | ForEach-Object -Process {
    Write-Output -InputObject $_
    & "$vmwarevdiskmanagerpath" -d $_
}

