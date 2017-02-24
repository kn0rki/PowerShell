#####################################   
  ## http://kunaludapi.blogspot.com   
  ## Version: 1   
  ## Tested this script on successfully  
  ## 1) Powershell v3   
  ## 2) Windows 7
  ## 3) vSphere 5.1 (vcenter, esxi, powercli)
  #####################################   
function Get-Ready {  
   <#  
   .SYNOPSIS  
   This single function provide multiple reports and information. ie: convert ready value to readable format (for realtime, day, week, month, year).  
   .DESCRIPTION  
   This single function provides multiple information from esxi host, as list below,  
   VM's CPU usage, CPU usage Mhz, CPU ready  
   vCPU allocated to VM (breaked into Sockets and Core)  
   VMHost Name   
   Physical CPU information of VMhost (breaked into Sockets and Core)  
   To convert between the CPU ready summation value in vCenter's performance charts and the CPU ready % value that you see in esxtop, you must use a formula.  
   The formula requires you to know the default update intervals for the performance charts. These are the default update intervals for each chart:   
   Realtime: 20 seconds  
   Past Day: 5 minutes (300 seconds)  
   Past Week: 30 minutes (1800 seconds)  
   Past Month: 2 hours (7200 seconds)  
   Past Year: 1 day (86400 seconds)  
   To calculate the CPU ready % from the CPU ready summation value, use this formula:  
   (CPU summation value / (<chart default update interval in seconds> * 1000)) * 100 = CPU ready %  
   Example: The Realtime stats for a virtual machine in vCenter might have an average CPU ready summation value of 1000. Use the appropriate values with the formula to get the CPU ready %.  
   (1000 / (20s * 1000)) * 100 = 5% CPU ready  
   For more infor check on vmware KB 2002181   
   .PARAMETER VM  
   Virtual machine name  
   .INPUTS  
   String.System.Management.Automation.PSObject.  
   .OUTPUTS  
   None.  
   .EXAMPLE  
   PS>Get-VMHost esxihost.fqdn | Get-Ready  
   If you wrap this script inside function you can use it as a command. For more information on using this script check http://kunaludapi.blogspot.com  
   Retrive report for vm from perticular VMHost  
   .NOTES  
   To see the examples, type: "get-help Set-VMHostSSH -examples".  
   For more information, type: "get-help Set-VMHostSSH -detailed".  
   For technical information, type: "get-help Set-VMHostSSH -full".  
   #>  
   [CmdletBinding()]  
   param(  
   [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]  
   [String]$Name) #param  
   begin {Add-PSSnapin vmware.vimautomation.core}#begin  
   process {  
     $Stattypes = "cpu.usage.average", "cpu.usagemhz.average", "cpu.ready.summation"  
     foreach ($esxi in $(Get-VMHost $Name)) {  
       $vmlist = $esxi | Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}  
       $esxiCPUSockets = $esxi.ExtensionData.Summary.Hardware.NumCpuPkgs   
       $esxiCPUcores = $esxi.ExtensionData.Summary.Hardware.NumCpuCores/$esxiCPUSockets  
       $TotalesxiCPUs = $esxiCPUSockets * $esxiCPUcores  
       foreach ($vm in $vmlist) {  
         $VMCPUNumCpu = $vm.NumCpu  
         $VMCPUCores = $vm.ExtensionData.config.hardware.NumCoresPerSocket  
         $VMCPUSockets = $VMCPUNumCpu / $VMCPUCores  
         $GroupedRealTimestats = Get-Stat -Entity $vm -Stat $Stattypes -Realtime -Instance "" -ErrorAction SilentlyContinue | Group-Object MetricId  
         $RealTimeCPUAverageStat = "{0:N2}" -f $($GroupedRealTimestats | Where-Object {$_.Name -eq "cpu.usage.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $RealTimeCPUUsageMhzStat = "{0:N2}" -f $($GroupedRealTimestats | Where-Object {$_.Name -eq "cpu.usagemhz.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $RealTimeReadystat = $GroupedRealTimestats | Where-Object {$_.Name -eq "cpu.ready.summation"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average  
         $RealTimereadyvalue = [math]::Round($(($RealTimeReadystat / (20 * 1000)) * 100), 2)  
         $Groupeddaystats = Get-Stat -Entity $vm -Stat $Stattypes -Start (get-date).AddDays(-1) -Finish (get-date) -IntervalMins 5 -Instance "" -ErrorAction SilentlyContinue | Group-Object MetricId  
         $dayCPUAverageStat = "{0:N2}" -f $($Groupeddaystats | Where-Object {$_.Name -eq "cpu.usage.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $dayCPUUsageMhzStat = "{0:N2}" -f $($Groupeddaystats | Where-Object {$_.Name -eq "cpu.usagemhz.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $dayReadystat = $Groupeddaystats | Where-Object {$_.Name -eq "cpu.ready.summation"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average  
         $dayreadyvalue = [math]::Round($(($dayReadystat / (300 * 1000)) * 100), 2)  
         $Groupedweekstats = Get-Stat -Entity $vm -Stat $Stattypes -Start (get-date).AddDays(-7) -Finish (get-date) -IntervalMins 30 -Instance "" -ErrorAction SilentlyContinue | Group-Object MetricId  
         $weekCPUAverageStat = "{0:N2}" -f $($Groupedweekstats | Where-Object {$_.Name -eq "cpu.usage.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $weekCPUUsageMhzStat = "{0:N2}" -f $($Groupedweekstats | Where-Object {$_.Name -eq "cpu.usagemhz.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $weekReadystat = $Groupedweekstats | Where-Object {$_.Name -eq "cpu.ready.summation"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average  
         $weekreadyvalue = [math]::Round($(($weekReadystat / (1800 * 1000)) * 100), 2)  
         $Groupedmonthstats = Get-Stat -Entity $vm -Stat $Stattypes -Start (get-date).AddDays(-30) -Finish (get-date) -IntervalMins 120 -Instance "" -ErrorAction SilentlyContinue | Group-Object MetricId  
         $monthCPUAverageStat = "{0:N2}" -f $($Groupedmonthstats | Where-Object {$_.Name -eq "cpu.usage.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $monthCPUUsageMhzStat = "{0:N2}" -f $($Groupedmonthstats | Where-Object {$_.Name -eq "cpu.usagemhz.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $monthReadystat = $Groupedmonthstats | Where-Object {$_.Name -eq "cpu.ready.summation"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average  
         $monthreadyvalue = [math]::Round($(($monthReadystat / (7200 * 1000)) * 100), 2)        
         $Groupedyearstats = Get-Stat -Entity $vm -Stat $Stattypes -Start (get-date).AddDays(-365) -Finish (get-date) -IntervalMins 1440 -Instance "" -ErrorAction SilentlyContinue | Group-Object MetricId  
         $yearCPUAverageStat = "{0:N2}" -f $($Groupedyearstats | Where-Object {$_.Name -eq "cpu.usage.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $yearCPUUsageMhzStat = "{0:N2}" -f $($Groupedyearstats | Where-Object {$_.Name -eq "cpu.usagemhz.average"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average)  
         $yearReadystat = $Groupedyearstats | Where-Object {$_.Name -eq "cpu.ready.summation"} | Select-Object -ExpandProperty Group | Measure-Object -Average Value | Select-Object -ExpandProperty Average  
         $yearreadyvalue = [math]::Round($(($yearReadystat / (86400 * 1000)) * 100), 2)    
         $data = New-Object psobject  
         $data | Add-Member -MemberType NoteProperty -Name VM -Value $vm.name  
         $data | Add-Member -MemberType NoteProperty -Name VMTotalCPUs -Value $VMCPUNumCpu   
         $data | Add-Member -MemberType NoteProperty -Name VMTotalCPUSockets -Value $VMCPUSockets  
         $data | Add-Member -MemberType NoteProperty -Name VMTotalCPUCores -Value $VMCPUCores  
         $data | Add-Member -MemberType NoteProperty -Name "RealTime Usage Average%" -Value $RealTimeCPUAverageStat  
         $data | Add-Member -MemberType NoteProperty -Name "RealTime Usage Mhz" -Value $RealTimeCPUUsageMhzStat  
         $data | Add-Member -MemberType NoteProperty -Name "RealTime Ready%" -Value $RealTimereadyvalue  
         $data | Add-Member -MemberType NoteProperty -Name "Day Usage Average%" -Value $dayCPUAverageStat  
         $data | Add-Member -MemberType NoteProperty -Name "Day Usage Mhz" -Value $dayCPUUsageMhzStat  
         $data | Add-Member -MemberType NoteProperty -Name "Day Ready%" -Value $dayreadyvalue  
         $data | Add-Member -MemberType NoteProperty -Name "week Usage Average%" -Value $weekCPUAverageStat  
         $data | Add-Member -MemberType NoteProperty -Name "week Usage Mhz" -Value $weekCPUUsageMhzStat  
         $data | Add-Member -MemberType NoteProperty -Name "week Ready%" -Value $weekreadyvalue  
         $data | Add-Member -MemberType NoteProperty -Name "month Usage Average%" -Value $monthCPUAverageStat  
         $data | Add-Member -MemberType NoteProperty -Name "month Usage Mhz" -Value $monthCPUUsageMhzStat  
         $data | Add-Member -MemberType NoteProperty -Name "month Ready%" -Value $monthreadyvalue  
         $data | Add-Member -MemberType NoteProperty -Name "Year Usage Average%" -Value $yearCPUAverageStat  
         $data | Add-Member -MemberType NoteProperty -Name "Year Usage Mhz" -Value $yearCPUUsageMhzStat  
         $data | Add-Member -MemberType NoteProperty -Name "Year Ready%" -Value $yearreadyvalue  
         $data | Add-Member -MemberType NoteProperty -Name VMHost -Value $esxi.name  
         $data | Add-Member -MemberType NoteProperty -Name VMHostCPUSockets -Value $esxiCPUSockets  
         $data | Add-Member -MemberType NoteProperty -Name VMHostCPUCores -Value $esxiCPUCores  
         $data | Add-Member -MemberType NoteProperty -Name TotalVMhostCPUs -Value $TotalesxiCPUs  
         $data  
       } #foreach ($vm in $vmlist)  
     }#foreach ($esxi in $(Get-VMHost $Name))  
   } #process  
 } #Function Get-Ready  