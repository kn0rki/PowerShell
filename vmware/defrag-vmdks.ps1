#Defrag all Vmware Workstation VMDK Files via vmware-vdiskmanager.exe


param(
	[string]$vmdkpath = ".\",
	[string]$vmwarevdiskmanagerpath = "G:\Programme\VMware Workstation\vmware-vdiskmanager.exe"
)

$files = Get-ChildItem -Path $vmdkpath -Recurse | ?{ $_.Name -like "*.vmdk"} | %{echo $_.VersionInfo.Filename}
$files | % { echo $_;& "$vmwarevdiskmanagerpath" -d $_}

