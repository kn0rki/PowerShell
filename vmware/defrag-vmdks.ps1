#Defrag all Vmware Workstation VMDK Files via vmware-vdiskmanager.exe


param(
	[string]$vmdkpath = ".\",
	[string]$vmwarevdiskmanagerpath
)

if(!($vmwarevdiskmanagerpath)){
	$vmwarevdiskmanagerpath = (get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation\").installpath
	$vmwarevdiskmanagerpath += "vmware-vdiskmanager.exe"
}


$files = Get-ChildItem -Path $vmdkpath -Recurse | ?{ $_.Name -like "*.vmdk"} | %{echo $_.VersionInfo.Filename}
$files | % { echo $_;& "$vmwarevdiskmanagerpath" -d $_}

