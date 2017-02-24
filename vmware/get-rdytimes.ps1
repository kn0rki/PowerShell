$myCol = @()
ForEach ($VMHost in (Get-VMHost | sort-object Name)) {
	ForEach ($VM in ($VMHost | Get-VM | where-object {$_.PowerState -ne “PoweredOff”}  | sort-object Name))
		{
		# Gather Stats
		$Ready = $VM | Get-Stat -Stat Cpu.Ready.Summation -RealTime
		$Used = $VM | Get-Stat -Stat Cpu.Used.Summation -RealTime
		$Wait = $VM | Get-Stat -Stat Cpu.Wait.Summation -RealTime
		For ($a = 0; $a -lt $VM.NumCpu; $a++) {
			$myObj = "" | select-object VMHost, VM, Instance, %RDY, %USED, %WAIT
			$myObj.VMHost = $VMHost.Name
			$myObj.VM = $VM.Name
			$myObj.Instance = $a
			$myObj."%RDY" = [Math]::Round((($Ready | where-object {$_.Instance -eq $a} | Measure-Object -Property Value -Average).Average)/200,1)
			$myObj."%USED" = [Math]::Round((($Used | where-object {$_.Instance -eq $a} | Measure-Object -Property Value -Average).Average)/200,1)
			$myObj."%WAIT" = [Math]::Round((($Wait | where-object {$_.Instance -eq $a} | Measure-Object -Property Value -Average).Average)/200,1)
			$myCol += $myObj
			
		}
		
		Clear-Variable Ready -ErrorAction SilentlyContinue 
		Clear-Variable Wait -ErrorAction SilentlyContinue 
		Clear-Variable Used -ErrorAction SilentlyContinue 
		Clear-Variable myObj -ErrorAction SilentlyContinue
		}
		
}
$myCol