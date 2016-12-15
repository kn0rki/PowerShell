<#
    .SYNOPSIS
    Install-Exchange15
   
    Michel de Rooij
    michel@eightwone.com
	 
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 2.4, July 6th, 2016

    Thanks to Maarten Piederiet, Thomas Stensitzki, Brian Reid, Martin Sieber, Sebastiaan Brozius and everyone who provided feedback.
    
    .DESCRIPTION
    This script can install Exchange 2013/2016 prerequisites, optionally create the Exchange 
    organization (prepares Active Directory) and installs Exchange Server. When the AutoPilot switch is 
    specified, it will do all the required rebooting and automatic logging on using provided credentials. 
    To keep track of provided parameters and state, it uses an XML file; if this file is 
    present, this information will be used to resume the process.
	
    .LINK
    http://eightwone.com
    
    .NOTES
    Requirements:
    - Windows Server 2008 R2 SP1, Windows Server 2012 or Windows Server 2012 R2;
    - Domain-joined system;
    - "AutoPilot" mode requires account with administrator privileges;
    - When you let the script prepare AD, the account needs proper permissions;
    - Edge role not yet supported

    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial community release
    1.01    Added logic to prepare AD when organization present
            Fixed checks and logic to prepare AD
            Added testing for domain mixed/native mode
            Added testing for forest functional level
    1.02    Fixed small typo in post-prepare AD function
    1.03    Replaced installing most OS features in favor of /InstallWindowsComponents
            Removed installation of Office Filtering Pack
    1.1     When used for AD preparation, RSAT-ADDS-Tools won't be uninstalled
            Pending reboot detection. In AutoPilot, script will reboot and restart phase.
            Installs Server-Media-Foundation feature (UCMA 4.0 requirement)
            Validates provided credentials for AutoPilot
            Check OS version as string (should accomodate non-US OS)
    1.5     Added support for WS2008R2 (i.e. added prereqs NET45, WMF3), IEESC toggling, 
            KB974405, KB2619234, KB2758857 (supersedes KB2533623). Inserted phase for
            WS2008R2 to install hotfixes (+reboot); this phase is skipped for WS2012. 
            Added InstallPath to AutoPilot set (or default won't be set).
    1.51    Rewrote Validate-Credentials due to missing .NET 3.5 Out of the Box in WS2008R2.
            Testing for proper loading of servermanager module in WS2008R2.
    1.52    Fix .NET / PrepareAD order for WS2008R2, relocated RebootPending check
    1.53    Fix phase of Forest/Domain Level check
    1.54    Added Parameter InstallBoth to install CAS and Mailbox, workaround as PoSHv2 
            can discriminate overlapping ParameterSets (resulting in AmbigiousParameterSet)
    1.55    Feature installation bug fix on WS2012
    1.56    Changed logic of final cleanup
    1.6     Code cleanup (merged KB/QFE/package functions)
            Fixed Verbose setting not being restored when script continues after reboot
            Renamed InstallBoth to InstallMultiRole
            Added 'Yes to All' option to extract function to prevent overwrite popup
            Added detection of setup file version
            Added switch IncludeFixes, which will install recommended hotfixes 
            (2008R2:KB2803754,KB2862063 2012:KB2803755,KB2862064) and KB2880833 for CU2 & CU3.
    1.61    Fixed XML not found issue when specifying different InstallPath (Cory Wood)
    1.7     Added Exchange 2013 SP1 & WS2012R2 support
            Added installing .NET Framework 4.51 (2008 R2 & 2012 - 2012R2 has 4.51)
            Added DisableRetStructPinning for Mailbox roles 
            Added KB2938053 (SP1 Transport Agent Fix)
            Added switch InstallFilterPack to install Office Filter Pack (OneNote & Publisher support)
            Fixed Exchange failed setup exit code anomaly
    1.71    Uncommented RunOnce line - AutoPilot should work again
            Using strings for OS version comparisons (should fix issue w/localized OS)
            Fixed issue installing .NET 4.51 on WS2012 ('all in one' kb2858728 contains/reports 
            WS2008R2/kb958488 versus WS2012/kb2881468
            Fixed inconsistency with .NET detection in WS2012
    1.72    Added CU5 support
            Added KB2971467 (CU5 Disable Shared Cache Service Managed Availability probes)
    1.73    Added CU6 support
            Added KB2997355 (Exchange Online mailboxes cannot be managed by using EAC)
            Added .NET Framework 4.52
            Removed DisableRetStructPinning (not required for .NET 4.52 or later)
    1.8     Added CU7 support
    1.9     Added CU8 support
            Fixed CU6/CU7 detection
            Added (temporary) clearing of Execution Policy GPO value
            Added Forest Level check to throw warning when it can't read value
            Added KB2985459 for WS2012
            Using different service to detect installed version
            Installs WMF4/NET452 for supported Exchange versions
            Added UseWMF3 switch to use WMF3 on WS2008R2
    2.0     Renamed script to Install-Exchange15
            Added CU9 support
            Added Exchange Server 2016 Preview support
            Fixed registry checks for GPO error messages
            Added ClearSCP switch to clear Autodiscover SCP record post-setup
            Added load-ExchangeModule() for post-configuration using EMS
            Bug fix .NET installation
            Modified AD checks to support multi-forest deployments
            Added access checks for Installation, MDB and Log locations
            Added checks for Exchange organization/Organization parameter
    2.03    Bug & typo fix
    2.1     Replaced ClearSCP with SCP param
            Added Lock switch to lock computer during installation
            Configures High Performance Power plan
            Added installing feature RSAT-Clustering-CmdInterface
            Added pagefile configuration when it's set to 'system managed'
    2.11    Added Exchange 2016 RTM support
            Removed Exchange 2016 Preview support
    2.12    Fixed pre-CU7 .NET installation logic
    2.2     Added (temporary) blocking unsupported .NET Framework 4.6.1 (KB3133990)
            Added recommended updates KB2884597 & KB2894875 for WS2012
            Changes to output so all output/verbose/warning/error get logged
            Added check to Organization for invalid characters
            Fixed specifying an Organization name containing spaces
    2.3     Added support up to Exchange 2013 CU12 / Exchange 2016 CU1
            Switched version detection to ExSetup, now follows Build
    2.31    Fixed output error messages
    2.4     Added support up to Exchange 2013 CU13 / Exchange 2016 CU2
            Added support for .NET 4.6.1 (Exchange 2013 CU13+ / Exchange 2016 CU2+)
            Added NONET461 switch, to use .NET 4.5.2, and block .NET 4.6.1
            Added installation of .NET 4.6.1 OS-dependent required hotfixes:
            * KB2919442 and KB2919355 (~700MB!) for WS2012R2 (prerequisites).
            * KB3146716 for WS2008/WS2008R2, KB3146714 for WS2012, and KB3146715 for WS2012R2.
            Added recommended Keep-Alive and RPC timeout settings
            Added DisableSSL3 to disable SSL3 (KB187498)
                
    .PARAMETER Organization
    Specifies name of the Exchange organization to create. When omitted, the step
    to prepare Active Directory (PrepareAD) will be skipped.

    .PARAMETER InstallMultiRole
    Specifies you want to install both Mailbox server and CAS roles (Exchange 2013 only).

    .PARAMETER InstallMailbox
    Specifies you want to install the Mailbox server role  (Exchange 2013/2016). 

    .PARAMETER InstallCAS
    Specifies you want to install the CAS role (Exchange 2013 only).

    .PARAMETER MDBName (optional)
    Specifies name of the initially created database.
    
    .PARAMETER MDBDBPath (optional)
    Specifies database path of the initially created database. Requires MDBName.

    .PARAMETER MDBLogPath (optional)
    Specifies log path of the initially created database. Requires MDBName.

    .PARAMETER InstallPath (optional)
    Specifies (temporary) location of where to store prerequisites files, log 
    files, etc. Default location is C:\Install.

    .PARAMETER NoSetup (optional)
    Specifies you don't want to setup Exchange (prepare/prerequisites only).

    .PARAMETER SourcePath
    Specifies location of the Exchange installation files (setup.exe).
    -
    .PARAMETER TargetPath
    Specifies the location where to install the Exchange binaries.

    .PARAMETER AutoPilot (switch)
    Specifies you want to automatically restart and logon using Account specified. When
    not specified, you will need to restart, logon and start the script again manually.

    .PARAMETER Credentials
    Specifies credentials to use for automatic logon. Use DOMAIN\User or user@domain. When 
    not specified, you will be prompted to enter credentials.

    .PARAMETER IncludeFixes
    Depending on operating system and detected Exchange version to install, will download 
    and install recommended hotfixes.

    .PARAMETER InstallFilterPack
    Adds installing Office filters for OneNote & Publisher support.

    .PARAMETER UseWMF3
    Installs WMF3 instead of WMF4 for Exchange 2013 SP1 or later.

    .PARAMETER NONET461
    Prevents installing .NET Framework 4.6.1 and uses 4.5.2, when supported Exchange is deployed.

    .PARAMETER DisableSSL3 
    Disables SSL3 after setup.

    .PARAMETER SCP 
    Reconfigures Autodiscover Service Connection Point record for this server post-setup, i.e.
    https://autodiscover.contoso.com/autodiscover/autodiscover.xml. If you want to remove the record, 
    set it to $null.

    .PARAMETER Lock
    Locks system when running script.

    .PARAMETER Phase
    Internal Use Only :)

    .EXAMPLE
    $Cred=Get-Credentials
    .\Install-Exchange15.ps1 -Organization Fabrikam -InstallMailbox -MDBDBPath C:\MailboxData\MDB1\DB -MDBLogPath C:\MailboxData\MDB1\Log -MDBName MDB1 -InstallPath C:\Install -AutoPilot -Credentials $Cred -SourcePath '\\server\share\Exchange 2013\mu_exchange_server_2013_x64_dvd_1112105' -SCP https://autodiscover.fabrikam.com/autodiscover/autodiscover.xml -Verbose

    .EXAMPLE
    .\Install-Exchange15.ps1 -InstallMailbox -MDBName MDB3 -MDBDBPath C:\MailboxData\MDB3\DB\MDB3.edb -MDBLogPath C:\MailboxData\MDB3\Log -AutoPilot -SourcePath '\\server\share\Exchange 2013\mu_exchange_server_2013_x64_dvd_1112105' -Verbose

    .EXAMPLE
    $Cred=Get-Credentials
    .\Install-Exchange15.ps1 -InstallMultiRole -AutoPilot -Credentials $Cred

    .EXAMPLE
    .\Install-Exchange15.ps1 -NoSetup -Autopilot

#>

[cmdletbinding(DefaultParameterSetName="AutoPilot")]
param(
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
		[ValidatePattern("(?# Organization Name can only consist of upper or lowercase A-Z, 0-9, spaces - not at beginning or end, hyphen or dash characters, can be up to 64 characters in length, and can't be empty)^[a-zA-Z0-9\-\–\—][a-zA-Z0-9\-\–\—\ ]{1,62}[a-zA-Z0-9\-\–\—]$")]
		[string]$Organization,
    	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
        	[switch]$InstallMultiRole,
	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
        	[switch]$InstallCAS,
   	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
    		[switch]$InstallMailbox,
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
		[string]$MDBName,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
		[string]$MDBDBPath,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
		[string]$MDBLogPath,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="AutoPilot")]
		[string]$InstallPath= "C:\Install",
	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
		[string]$SourcePath,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
		[string]$TargetPath,
	[parameter( Mandatory=$true, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
		[switch]$NoSetup= $false,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
		[switch]$AutoPilot,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
	        [System.Management.Automation.PsCredential]$Credentials,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [Switch]$IncludeFixes,
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [Switch]$InstallFilterPack,
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [Switch]$NoNet461,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [Switch]$UseWMF3,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [Switch]$DisableSSL3,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [String]$SCP='',
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
                [Switch]$Lock,
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="C")]
 	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="M")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="CM")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="NoSetup")]
	[parameter( Mandatory=$false, ValueFromPipelineByPropertyName=$false, ParameterSetName="AutoPilot")]
        	[ValidateRange(0,5)]
	        [int]$Phase
   )

process {

    $ERR_OK                         = 0
    $ERR_PROBLEMADPREPARE	        = 1001
    $ERR_UNEXPECTEDOS               = 1002
    $ERR_UNEXPTECTEDPHASE           = 1003
    $ERR_PROBLEMADDINGFEATURE	    = 1004
    $ERR_NOTDOMAINJOINED            = 1005
    $ERR_NOFIXEDIPADDRESS           = 1006
    $ERR_CANTCREATETEMPFOLDER       = 1007
    $ERR_UNKNOWNROLESSPECIFIED      = 1008
    $ERR_NOACCOUNTSPECIFIED         = 1009
    $ERR_RUNNINGNONADMINMODE        = 1010
    $ERR_AUTOPILOTNOSTATEFILE       = 1011
    $ERR_ADMIXEDMODE                = 1012
    $ERR_ADFORESTLEVEL              = 1013
    $ERR_INVALIDCREDENTIALS         = 1014
    $ERR_CANTLOADSERVERMANAGER      = 1015
    $ERR_MDBDBLOGPATH               = 1016
    $ERR_MISSINGORGANIZATIONNAME    = 1017
    $ERR_ORGANIZATIONNAMEMISMATCH   = 1018
    $ERR_PROBLEMPACKAGEDL           = 1120
    $ERR_PROBLEMPACKAGESETUP        = 1121
    $ERR_PROBLEMPACKAGEEXTRACT      = 1122
    $ERR_PROBLEMFILTERPACKDL        = 1131
    $ERR_PROBLEMFILTERPACKSETUP     = 1132
    $ERR_PROBLEMFILTERPACKSP1DL     = 1133
    $ERR_PROBLEMFILTERPACKSP1SETUP  = 1134
    $ERR_BADFORESTLEVEL             = 1151
    $ERR_BADDOMAINLEVEL             = 1152
    $ERR_NOTSUPPORTED               = 1153
    $ERR_MISSINGEXCHANGESETUP       = 1201
    $ERR_PROBLEMEXCHANGESETUP       = 1202

    $COUNTDOWN_TIMER                = 10
    $DOMAIN_MIXEDMODE               = 0
    $FOREST_LEVEL2003               = 2

    # Minimum FFL/DFL levels
    $EX2013_MINFORESTLEVEL          = 15137
    $EX2013_MINDOMAINLEVEL          = 13236
    $EX2016_MINFORESTLEVEL          = 15317
    $EX2016_MINDOMAINLEVEL          = 13236

    # Exchange Versions
    $EX2013_MAJOR                   = "15.0"
    $EX2016_MAJOR                   = "15.1"

    # Supported Exchange versions
    $EX2013STOREEXE_RTM             = '15.00.0516.032'
    $EX2013STOREEXE_CU1             = '15.00.0620.029'
    $EX2013STOREEXE_CU2             = '15.00.0712.024'
    $EX2013STOREEXE_CU3             = '15.00.0775.038'
    $EX2013STOREEXE_SP1             = '15.00.0847.032'
    $EX2013STOREEXE_CU5             = '15.00.0913.022'
    $EX2013STOREEXE_CU6             = '15.00.0995.029'
    $EX2013STOREEXE_CU7             = '15.00.1044.025'
    $EX2013STOREEXE_CU8             = '15.00.1076.009'
    $EX2013STOREEXE_CU9             = '15.00.1104.005'
    $EX2013STOREEXE_CU10            = '15.00.1130.007'
    $EX2013STOREEXE_CU11            = '15.00.1156.006'
    $EX2013STOREEXE_CU12            = '15.00.1178.004'
    $EX2013STOREEXE_CU13            = '15.00.1210.003'
    $EX2016STOREEXE_PRE             = '15.01.0225.016'
    $EX2016STOREEXE_RTM             = '15.01.0225.042'
    $EX2016STOREEXE_CU1             = '15.01.0396.030'
    $EX2016STOREEXE_CU2             = '15.01.0466.034'

    # Supported Operating Systems
    $WS2008R2_MAJOR                 = '6.1'
    $WS2012_MAJOR                   = '6.2'
    $WS2012R2_MAJOR                 = '6.3'
    
    Function Save-State( $State) {
        Write-MyVerbose "Saving state information to $StateFile"
        Export-Clixml -InputObject $State -Path $StateFile
    }

    Function Load-State() {
        $State= @{}
        If(Test-Path $StateFile) {
            $State= Import-Clixml -Path $StateFile -ErrorAction SilentlyContinue
            Write-MyVerbose "State information loaded from $StateFile"
        }
        Else {
            Write-Verbose "No state file found at $StateFile"
        }
        Return $State
    }

    Function Setup-TextVersion( $FileVersion) {
        $Versions= @{ 
            $EX2013STOREEXE_RTM= 'Exchange Server 2013 RTM';
            $EX2013STOREEXE_CU1= 'Exchange Server 2013 Cumulative Update 1';
            $EX2013STOREEXE_CU2= 'Exchange Server 2013 Cumulative Update 2';
            $EX2013STOREEXE_CU3= 'Exchange Server 2013 Cumulative Update 3';
            $EX2013STOREEXE_SP1= 'Exchange Server 2013 Service Pack 1';
            $EX2013STOREEXE_CU5= 'Exchange Server 2013 Cumulative Update 5';
            $EX2013STOREEXE_CU6= 'Exchange Server 2013 Cumulative Update 6';
            $EX2013STOREEXE_CU7= 'Exchange Server 2013 Cumulative Update 7';
            $EX2013STOREEXE_CU8= 'Exchange Server 2013 Cumulative Update 8';
            $EX2013STOREEXE_CU9= 'Exchange Server 2013 Cumulative Update 9';
            $EX2013STOREEXE_CU10= 'Exchange Server 2013 Cumulative Update 10';
            $EX2013STOREEXE_CU11= 'Exchange Server 2013 Cumulative Update 11';
            $EX2013STOREEXE_CU12= 'Exchange Server 2013 Cumulative Update 12';
            $EX2013STOREEXE_CU13= 'Exchange Server 2013 Cumulative Update 13';
            $EX2016STOREEXE_PRE= 'Exchange Server 2016 Preview';
            $EX2016STOREEXE_RTM= 'Exchange Server 2016 RTM';
            $EX2016STOREEXE_CU1= 'Exchange Server 2016 Cumulative Update 1';
            $EX2016STOREEXE_CU2= 'Exchange Server 2016 Cumulative Update 2';
        }
        if ($Versions[$FileVersion]) {
            $res= "$FileVersion ($($Versions[$FileVersion]))"
        }
        Else {
            $res= "$FileVersion (Unknown Version)"
        }
        return $res
    }
    Function File-DetectVersion( $File) {
        $res= 0
        If( Test-Path $File) {
            $res= (Get-Command $File).FileVersionInfo.ProductVersion
        }
        Else {
            $res= 0
        }
        return $res
    }

    Function Write-MyOutput( $Text) {
        Write-Output $Text
        $Location= Split-Path $State['TranscriptFile'] -Parent
        If( Test-Path $Location) {
            Write-Output "$(Get-Date -Format u): $Text" | Out-File $State['TranscriptFile'] -Append -ErrorAction SilentlyContinue
        }
    }

    Function Write-MyWarning( $Text) {
        Write-Warning $Text
        $Location= Split-Path $State['TranscriptFile'] -Parent
        If( Test-Path $Location) {
            Write-Output "$(Get-Date -Format u): [WARNING] $Text" | Out-File $State['TranscriptFile'] -Append -ErrorAction SilentlyContinue
        }
    }

    Function Write-MyError( $Text) {
        Write-Error $Text
        $Location= Split-Path $State['TranscriptFile'] -Parent
        If( Test-Path $Location) {
            Write-Output "$(Get-Date -Format u): [ERROR] $Text" | Out-File $State['TranscriptFile'] -Append -ErrorAction SilentlyContinue
        }
    }

    Function Write-MyVerbose( $Text) {
        Write-Verbose $Text
        $Location= Split-Path $State['TranscriptFile'] -Parent
        If( Test-Path $Location) {
            Write-Output "$(Get-Date -Format u): [VERBOSE] $Text" | Out-File $State['TranscriptFile'] -Append -ErrorAction SilentlyContinue
        }
    }

    Function Get-PSExecutionPolicy {
        $PSPolicyKey= Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell' -Name ExecutionPolicy -ErrorAction SilentlyContinue
        If( $PSPolicy) {
            Write-Warning "PowerShell Execution Policy is set to $($PSPolicy.ExecutionPolicy) through GPO"
        }
        Else {
            Write-MyVerbose "PowerShell Execution Policy not configured through GPO"
        }
        return $PSPolicy
    }

    Function Check-Package () {
        Param ( [String]$Package, [String]$URL, [String]$FileName, [String]$InstallPath)
        $res= $true
        If( !( Test-Path "$InstallPath\$FileName")) {
            If( $URL) {
                Write-MyOutput "$FileName not present, downloading $Package"
                Try{
                    Write-MyVerbose "Source: $URL"
                    Start-BitsTransfer -Source $URL -Destination "$InstallPath\$FileName"        
                }
                Catch{
                    Write-MyError "Problem downloading file from URL"
                    $res= $false
                }
            }
            Else {
                Write-Warning "$FileName not present, not downloading"
                $res= $false
            }
        }
        Else {
            Write-MyVerbose "$Package present ($InstallPath\$FileName)"
        }
        Return $res
    }

    Function is-Admin {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
        If( $currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) {
            return $true
        }
        Else {
            return $false
        }
    }

    Function is-MinimalBuild() {
        Param ( [String]$BuildNumber, [String]$ReferenceBuildNumber)
        $Temp= $BuildNumber.Split(".")
        $MajorBuildNumber= "$($Temp[0]).$($Temp[1])"
        $MinorBuildNumber= "$($Temp[2]).$($Temp[3])"
        $Temp= $ReferenceBuildNumber.Split(".")
        $MajorReferenceBuildNumber= "$($Temp[0]).$($Temp[1])"
        $MinorReferenceBuildNumber= "$($Temp[2]).$($Temp[3])"
        Return ($MajorBuildNumber -ge $MajorReferenceBuildNumber -and $MinorBuildNumber -ge $MinorReferenceBuildNumber)
    }

    Function is-RebootPending {
        $Pending= $False
        If( Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
            $Pending= $True
        }
        If( Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) {
            $Pending= $True
        }
        Return $Pending
    }

    Function Enable-RunOnce {
        Write-MyOutput "Set script to run once after reboot"
        $RunOnce= "$PSHome\powershell.exe -NoProfile -ExecutionPolicy Unrestricted -Command `"& `'$ScriptFullName`' -InstallPath `'$InstallPath`'`""
        Write-MyVerbose "RunOnce: $RunOnce"
        New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "$ScriptName"  -Value "$RunOnce" -ErrorAction SilentlyContinue| out-null
    }

    Function Disable-UAC {
        Write-MyVerbose "Disabling User Account Control"
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -Value 0 -ErrorAction SilentlyContinue| out-null
    }

    Function Enable-UAC {
        Write-MyVerbose "Enabling User Account Control"
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -Value 1 -ErrorAction SilentlyContinue| out-null
    }

    Function Disable-IEESC {
        Write-MyOutput "Disabling IE Enhanced Security Configuration"
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        Stop-Process -Name Explorer
    }
    
    Function Enable-IEESC {
        Write-MyVerbose "Enabling IE Enhanced Security Configuration"
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1
        Stop-Process -Name Explorer
    }

    Function validate-Credentials {
        $PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString $State["AdminPassword"]) ))
        $PlainTextAccount= $State["AdminAccount"]
        If( $PlainTextAccount.indexOf("\")) {
            $Parts= $PlainTextAccount.split("\")
            $Domain = $Parts[0]
            $UserName= $Parts[1]
        }
        Else {
            $Domain = $env:USERDOMAIN
            $UserName= $PlainTextAccount
        }
	try {
		$dc= New-Object DirectoryServices.DirectoryEntry( $Null, "$Domain\$UserName", $PlainTextPassword)
		If($dc.Name) {
			return $true
		}
		Else {
			Return $false
		}
	}
	catch {
		return $false
	}
	Return $false
    }

    Function Enable-AutoLogon {
        Write-MyVerbose "Enabling Automatic Logon"
        $PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString $State["AdminPassword"]) ))
        $PlainTextAccount= $State["AdminAccount"]
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 -ErrorAction SilentlyContinue| out-null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value $PlainTextAccount -ErrorAction SilentlyContinue| out-null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value $PlainTextPassword -ErrorAction SilentlyContinue| out-null
    }

    Function Disable-AutoLogon {
        Write-MyVerbose "Disabling Automatic Logon"
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -ErrorAction SilentlyContinue| out-null
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -ErrorAction SilentlyContinue| out-null
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -ErrorAction SilentlyContinue| out-null
    }

    Function Disable-OpenFileSecurityWarning {
        Write-MyVerbose "Disabling File Security Warning dialog"
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -ErrorAction SilentlyContinue |out-null
        New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -name "LowRiskFileTypes" -value ".exe;.msp;.msu" -ErrorAction SilentlyContinue |out-null
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -ErrorAction SilentlyContinue |out-null
        New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -name "SaveZoneInformation" -value 1 -ErrorAction SilentlyContinue |out-null
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Name "LowRiskFileTypes" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Name "SaveZoneInformation" -ErrorAction SilentlyContinue
    }

    Function Enable-OpenFileSecurityWarning {
        Write-MyVerbose "Enabling File Security Warning dialog"
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Name "LowRiskFileTypes" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Name "SaveZoneInformation" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Name "LowRiskFileTypes" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Name "SaveZoneInformation" -ErrorAction SilentlyContinue
    }

    Function StartWait-Extract ( $FilePath, $FileName) {
        Write-MyVerbose "Extracting $FilePath\$FileName to $FilePath"
        If( Test-Path "$FilePath\$FileName") {
            $TempNam= "$FilePath\$FileName.zip"
            Copy-Item "$FilePath\$FileName" "$TempNam" -Force
            $shellApplication = new-object -com shell.application
            $zipPackage = $shellApplication.NameSpace( $TempNam)
            $destFolder = $shellApplication.NameSpace( $FilePath)
            $destFolder.CopyHere( $zipPackage.Items(), 0x10)
            Remove-Item $TempNam
        }
        Else {
            Write-Warning "$FilePath\$FileName not found"
        }
    }

    Function StartWait-Process ( $FilePath, $FileName, $ArgumentList) {
        Write-MyVerbose "Executing $FilePath\$FileName $($ArgumentList -Join " ")"
        If( Test-Path "$FilePath\$FileName") {
            Switch( ([io.fileinfo]$Filename).extension.ToUpper()) {
                ".MSU" {
                    $ArgumentList+= @( "$FilePath\$FileName")
                    Start-Process -FilePath "$env:SystemRoot\System32\WUSA.EXE" -ArgumentList $ArgumentList -Wait -NoNewWindow
                }
                ".MSP" {
                    $ArgumentList+= @( "/update")
                    $ArgumentList+= @( "$FilePath\$FileName")
                    Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList $ArgumentList -Wait -NoNewWindow
                }
                default {
                    Start-Process -FilePath "$FilePath\$FileName" -ArgumentList $ArgumentList -Wait -NoNewWindow
                }
            }
        }
        Else {
            Write-Warning "$FilePath\$FileName not found"
        }
    }
    Function Get-ForestRootNC {
        return ([ADSI]"LDAP://RootDSE").rootDomainNamingContext
    }
    Function Get-RootNC {
        return ([ADSI]"").distinguishedName
    }

    Function Get-ForestFunctionalLevel {
        $NC= Get-ForestRootNC
        Try {
            $rval= ( ([ADSI]"LDAP://cn=partitions,cn=configuration,$NC").get("msDS-Behavior-Version") )
        }
        Catch {
            Write-MyError "Can't read Forest schema version, operator possible not member of Schema admin group"
        }
        return $rval
    }

    Function Test-DomainNativeMode {
        $NC= Get-RootNC
        return( ([ADSI]"LDAP://$NC").ntMixedDomain )
    }

    Function Get-ExchangeOrganization {
        $NC= Get-ForestRootNC
        Try {
            $ExOrgContainer= [ADSI]"LDAP://CN=Microsoft Exchange,CN=Services,CN=Configuration,$NC"
            $rval= ($ExOrgContainer.PSBase.Children | Where-Object { $_.objectClass -eq 'msExchOrganizationContainer' }).Name
        }
        Catch {
            Write-MyVerbose "Can't find Exchange Organization object"
            $rval= $null
        }
        return $rval
    }

    Function Test-ExchangeOrganization( $Organization) {
        $NC= Get-ForestRootNC
        return( [ADSI]"LDAP://CN=$Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,$NC")
    }

    Function Get-ExchangeForestLevel {
        $NC= Get-ForestRootNC
        return ( ([ADSI]"LDAP://CN=ms-Exch-Schema-Version-Pt,CN=Schema,CN=Configuration,$NC").rangeUpper )
    }

    Function Get-ExchangeDomainLevel {
        $NC= Get-RootNC
        return( ([ADSI]"LDAP://CN=Microsoft Exchange System Objects,$NC").objectVersion )
    }

    Function Clear-AutodiscoverServiceConnectionPoint( [string]$Name) {
        $NC= Get-RootNC
        $LDAPSearch= New-Object System.DirectoryServices.DirectorySearcher
        $LDAPSearch.SearchRoot= "LDAP://CN=Configuration,$NC"
        $LDAPSearch.Filter= "(&(cn=$Name)(objectClass=serviceConnectionPoint)(serviceClassName=ms-Exchange-AutoDiscover-Service)(|(keywords=67661d7F-8FC4-4fa7-BFAC-E1D7794C1F68)(keywords=77378F46-2C66-4aa9-A6A6-3E7A48B19596)))"
        $LDAPSearch.FindAll() | ForEach-Object {
            Write-MyVerbose "Removing object $($_.Path)"
            ([ADSI]($_.Path)).DeleteTree()
        }
    }

   Function Set-AutodiscoverServiceConnectionPoint( [string]$Name, [string]$ServiceBinding) {
        $NC= Get-RootNC
        $LDAPSearch= New-Object System.DirectoryServices.DirectorySearcher
        $LDAPSearch.SearchRoot= "LDAP://CN=Configuration,$NC"
        $LDAPSearch.Filter= "(&(cn=$Name)(objectClass=serviceConnectionPoint)(serviceClassName=ms-Exchange-AutoDiscover-Service)(|(keywords=67661d7F-8FC4-4fa7-BFAC-E1D7794C1F68)(keywords=77378F46-2C66-4aa9-A6A6-3E7A48B19596)))"
        $LDAPSearch.FindAll() | ForEach-Object {
            Write-MyVerbose "Setting serviceBindingInformation on $($_.Path) to $ServiceBinding"
            Try {
                $SCPObj= $_.GetDirectoryEntry()
                [void]$SCPObj.Put( 'serviceBindingInformation', $ServiceBinding)
                $SCPObj.SetInfo()
            }
            Catch {
                Write-MyError "Problem setting serviceBindingInformation property: $($Error[0])"
            }
        }
    }

    Function Get-LocalFQDNHostname {
        return ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName
    }

    Function Load-ExchangeModule {
        Write-MyVerbose "Loading Exchange PowerShell module"
        If( -not ( Get-Command Connect-ExchangeServer -ErrorAction SilentlyContinue)) {
            $SetupPath= (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup -Name MsiInstallPath -ErrorAction SilentlyContinue).MsiInstallPath
            If( $SetupPath -and (Test-Path "$SetupPath\bin\RemoteExchange.ps1" )) {
                . "$SetupPath\bin\RemoteExchange.ps1" | Out-Null
                Try {
                    Connect-ExchangeServer (Get-LocalFQDNHostname)
                }
                Catch {
                    Write-MyError 'Problem loading Exchange module'
                }
            }
            Else {
                Write-Warning "Can't determine installation path to load Exchange module"
            }
        }
        Else {
            Write-Warning 'Exchange module already loaded'
        }
    }

    Function Install-Exchange15_ {
        $ver= $State['MajorSetupVersion']
        Write-MyOutput "Installing Microsoft Exchange Server ($ver)"
        If( $State['MajorSetupVersion'] -ge $EX2016_MAJOR) {
            $PresenceKey= "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{CD981244-E9B8-405A-9026-6AEB9DCEF1F1}"
        }
        Else {
            $PresenceKey= "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{4934D1EA-BE46-48B1-8847-F1AF20E892C1}"
        }
        $roles= @()
        If( $State["InstallMailbox"]) {
            $roles+= "Mailbox"
        }
        If( $State["InstallCAS"]) {
            If( $State['MajorSetupVersion'] -ge $EX2016_MAJOR) {
                    Write-Warning 'Ignoring specified InstallCAS option for Exchange 2016'
            }
            Else {
                $roles+= "ClientAccess"
            }
        }
	    $RolesParm= $roles -Join ","
        $Params= ("/mode:install", "/roles:$RolesParm", "/IAcceptExchangeServerLicenseTerms", "/InstallWindowsComponents")
        If( $State["InstallMailbox"]) {
            If( $State["InstallMDBName"]) {
                $Params+= "/MdbName:$($State["InstallMDBName"])"
            }
            If( $State["InstallMDBDBPath"]) {
                $Params+= "/DBFilePath:`"$($State["InstallMDBDBPath"])\$($State["InstallMDBName"]).edb`""
            }
            If( $State["InstallMDBLogPath"]) {
                $Params+= "/LogFolderPath:`"$($State["InstallMDBLogPath"])\$($State["InstallMDBName"])\Log`""
            }
        }
        If( $State["TargetPath"]) {
            $Params+= "/TargetDir:`"$($State["TargetPath"])`""
        }
        $Params+= "/DoNotStartTransport"

        StartWait-Process $State["SourcePath"] "setup.exe" $Params
        If( !( Get-Item $PresenceKey -ErrorAction SilentlyContinue)){
                Write-MyError "Problem installing Exchange"
                Exit $ERR_PROBLEMEXCHANGESETUP
        }
    }

    Function Prepare-Exchange {
        Write-MyOutput "Preparing Active Directory"
        $params= @()
        Write-MyOutput "Checking Exchange organization existence"
        If( ( Test-ExchangeOrganization $State["OrganizationName"]) -ne $null) {
            $params+= "/PrepareAD", "/OrganizationName:`"$($State["OrganizationName"])`""
        }
        Else {
            Write-MyOutput "Organization exist; checking Exchange Forest Schema and Domain versions"
            $forestlvl= Get-ExchangeForestLevel
            $domainlvl= Get-ExchangeDomainLevel
            Write-MyOutput "Exchange Forest Schema version: $forestlvl, Domain: $domainlvl)"
            If( $State['MajorSetupVersion'] -ge $EX2016_MAJOR) {
                $MinFFL= $EX2016_MINFORESTLEVEL
                $MinDFL= $EX2016_MINDOMAINLEVEL
            }
            Else {
                $MinFFL= $EX2013_MINFORESTLEVEL
                $MinDFL= $EX2013_MINDOMAINLEVEL
            }
            If(( $forestlvl -lt $MinFFL) -or ( $domainlvl -lt $MinDFL)) {
                Write-MyOutput "Exchange Forest Schema or Domain needs updating (Required: $MinFFL/$MinDFL)"
                $params+= "/PrepareAD"

            }
            Else {
                Write-MyOutput "Active Directory looks already updated".
            }
        }
        If ($params.count -gt 0) {
            Write-MyOutput "Preparing AD, Exchange organization will be $($State["OrganizationName"])"
            $params+= "/IAcceptExchangeServerLicenseTerms"
            StartWait-Process $State["SourcePath"] "setup.exe" $params
            If( ( ( Test-ExchangeOrganization $State["OrganizationName"]) -eq $null) -or
                ( (Get-ExchangeForestLevel) -lt $MinFFL) -or
                ( (Get-ExchangeDomainLevel) -lt $MinDFL)) {
                Write-MyError "Problem updating schema, domain or Exchange organization"
                Exit $ERR_PROBLEMADPREPARE
            }
        }
        Else {
            Write-Warning "Exchange organization $($State["OrganizationName"]) already exists, skipping this step"
        }
    }

    Function Install-WindowsFeatures( $MajorOSVersion) {
        Write-MyOutput "Installing Windows Features"

        If ($MajorOSVersion -eq $WS2008R2_MAJOR) {
            Import-Module ServerManager
            If(!( Get-Module ServerManager )) {
                Write-MyError "Problem loading ServerManager module"
                Exit $ERR_CANTLOADSERVERMANAGER
            }
            $Feats= ("NET-Framework", "Desktop-Experience", "RSAT-ADDS", "Bits", "RSAT-Clustering-CmdInterface")
        }
        Else {
            $Feats= ("Desktop-Experience", "Server-Media-Foundation", "RSAT-ADDS", "Bits", "RSAT-Clustering-CmdInterface")
        }

        If( $MajorOSVersion -eq $WS2008R2_MAJOR) {
            Add-WindowsFeature $Feats | out-null
        }
        Else {
            Install-WindowsFeature $Feats | out-null
        }

        ForEach( $Feat in $Feats) {
            If( !( Get-WindowsFeature ($Feat))) {
                Write-MyError "Feature $Feat appears not to be installed"
                Exit $ERR_PROBLEMADDINGFEATURE
            }
        }
    }

    Function Package-IsInstalled( $PackageID) {
        Write-MyVerbose "Checking if package $PackageID is installed .."
        $PresenceKey= $null
        $PresenceKey= (Get-WmiObject win32_quickfixengineering | Where-Object { $_.HotfixID -eq $PackageID }).HotfixID
        If( !( $PresenceKey)) {
            $PresenceKey= (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$PackageID" -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName 
            If(!( $PresenceKey)) {
                # Alternative (seen KB2803754, 2802063 register here)
                $PresenceKey= (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$PackageID" -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName 
                If( !( $PresenceKey)){
                    # Alternative (Office2010FilterPack SP1)
                    $PresenceKey= (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$PackageID" -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
                }
            }
        }
        return $PresenceKey
    }

    Function Package-Install () {
        Param ( [String]$PackageID, [string]$Package, [String]$FileName, [String]$OnlineURL, [array]$Arguments)

        Write-MyOutput "Processing $Package ($PackageID)"
        $PresenceKey= Package-IsInstalled $PackageID
        If( !( $PresenceKey )){

            If( $FileName.contains("|")) {

                # Filename contains filename (dl) and package name (after extraction)
                $PackageFile= ($FileName.Split("|"))[1]
                $FileName= ($FileName.Split("|"))[0]
                If( !( Check-Package $Package "" $FileName $State["InstallPath"])) {

                    # Download & Extract
                    If( !( Check-Package $Package $OnlineURL $PackageFile $State["InstallPath"])) {
                        Write-MyError "Problem downloading/accessing $Package"
                        Exit $ERR_PROBLEMPACKAGEDL
                    }
                    Write-MyOutput "Extracting Hotfix Packge $Package"
                    StartWait-Extract $State["InstallPath"] $PackageFile 

                    If( !( Check-Package $Package $OnlineURL $PackageFile $State["InstallPath"])) {
                        Write-MyError "Problem downloading/accessing $Package"
                        Exit $ERR_PROBLEMPACKAGEEXTRACT
                    }
                }
                Write-MyOutput "Installing $Package"
                StartWait-Process $State["InstallPath"] $FileName $Arguments

            }
            Else {

                If( !( Check-Package $Package $OnlineURL $FileName $State["InstallPath"])) {
                    Write-MyError "Problem downloading/accessing $Package"
                    Exit $ERR_PROBLEMPACKAGEDL
                }
                StartWait-Process $State["InstallPath"] $FileName $Arguments
            }
            
            $PresenceKey= Package-IsInstalled $PackageID
            If( !( $PresenceKey)){
                Write-MyError "Problem installing $Package"
                Exit $ERR_PROBLEMPACKAGESETUP
            }
            Else {
                Write-MyOutput "Succesfully installed $Package"
            }
        }
        Else {
            Write-MyVerbose "$Package already installed"
        }    
    }

    Function Enable-IFilters {
        # From: Brian Reid (@BrianReidC7)
        # Note: Requires restarting "Microsoft Exchange Transport" and "Microsoft Filtering Management Service", but reboot will take care of that
        Write-MyOutput "Enabling OneNote and Publisher filtering" 
        $iFilterDirName = "C:\Program Files\Common Files\Microsoft Shared\Filters\"
        $KeyParent = "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\HubTransportRole"
        $CLSIDKey = "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\HubTransportRole\CLSID"
        $FiltersKey = "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\HubTransportRole\filters"
        $ONEFilterLocation = $iFilterDirName + "\ONIFilter.dll"
        $PUBFilterLocation = $iFilterDirName + "\PUBFILT.dll"
        $ONEGuid    ="{B8D12492-CE0F-40AD-83EA-099A03D493F1}"
        $PUBGuid    ="{A7FD8AC9-7ABF-46FC-B70B-6A5E5EC9859A}" 
        New-Item -Path $KeyParent -Name CLSID -ErrorAction SilentlyContinue -Force| Out-Null
        New-Item -Path $KeyParent -Name filters -ErrorAction SilentlyContinue -Force | Out-Null
        New-Item -Path $CLSIDKey -Name $ONEGuid -Value $ONEFilterLocation -Type String -Force| Out-Null
        New-Item -Path $CLSIDKey -Name $PUBGuid -Value $PUBFilterLocation -Type String -Force| Out-Null
        New-ItemProperty -Path "$CLSIDKey\$ONEGuid" -Name "ThreadingModel" -Value "Both" -Type String -Force| Out-Null
        New-ItemProperty -Path "$CLSIDKey\$PUBGuid" -Name "ThreadingModel" -Value "Both" -Type String -Force| Out-Null
        New-ItemProperty -Path "$CLSIDKey\$ONEGuid" -Name "Flags" -Value "1" -Type Dword -Force| Out-Null
        New-ItemProperty -Path "$CLSIDKey\$PUBGuid" -Name "Flags" -Value "1" -Type Dword -Force| Out-Null
        New-Item -Path $FiltersKey -Name ".one" -Value $ONEGuid -Type String -Force| Out-Null
        New-Item -Path $FiltersKey -Name ".pub" -Value $PUBGuid -Type String -Force| Out-Null 
        $acl = Get-Acl $KeyParent
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NETWORK SERVICE","ReadKey","Allow")
        $acl.SetAccessRule($rule)
        $acl | Set-Acl -Path $KeyParent
    }

    Function DisableSharedCacheServiceProbe {
        # Taken from DisableSharedCacheServiceProbe.ps1
        # Copyright (c) Microsoft Corporation. All rights reserved. 
        Write-MyOutput "Applying DisableSharedCacheServiceProbe (KB2971467, 'Shared Cache Service Restart' Probe Fix)"
        $exchangeInstallPath = get-itemproperty -path HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup -ErrorAction SilentlyContinue
        if ($exchangeInstallPath -ne $null -and (Test-Path $exchangeInstallPath.MsiInstallPath)) {
            $ProbeConfigFile= Join-Path ( $exchangeInstallPath.MsiInstallPath) ('Bin\Monitoring\Config\SharedCacheServiceTest.xml')
	        if (Test-Path $ProbeConfigFile) {
	            $date = get-date -format s
	            $ext = ".orig_" + $date.Replace(':', '-');
	            $backup = $ProbeConfigFile + $ext
	            $xmlBackup = [XML](Get-Content $ProbeConfigFile);
	            $xmlBackup.Save($backup);	
	
	            $xmlDoc = [XML](Get-Content $ProbeConfigFile);
	            $definition = $xmlDoc.Definition.MaintenanceDefinition;
	
	            if($definition -eq $null) {
                    Write-MyError "KB2971467: Expected XML node Definition.MaintenanceDefinition.ExtensionAttributes not found. Skipping."
                }
                Else {
                    $modified = $false;
                    if ($definition.Enabled -ne $null -and $definition.Enabled -ne "false") {
                        $definition.Enabled = "false";
                        $modified = $true;
                    }
	                If($modified) {
                        $xmlDoc.Save($ProbeConfigFile);
                        Write-MyOutput "Finished KB2971467, Saved $ProbeConfigFile"
                    }
                    Else {
                        Write-MyOutput "Finished KB2971467, No values modified."
                    }
                }
            }
            Else {
	            Write-MyError "KB2971467: Did not find file in expected location, skipping $ProbeConfigFile"
	        }
        }
        Else {
            Write-MyError 'KB2971467: Unable to locate Exchange install path'
        }
    }

    Function Exchange2013-KB2938053-FixIt {
        # Taken from Exchange2013-KB2938053-FixIt.ps1
        # Copyright (c) Microsoft Corporation. All rights reserved. 
        Write-MyOutput "Applying Exchange2013-KB2938053-FixIt (KB2938053, Transport Agent Fix)"
        $baseDirectory = "$Env:Windir\Microsoft.NET\assembly\GAC_MSIL"
        $policyDirectories = @{ "policy.14.0.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy14.0.cfg";`
                        "policy.14.0.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy14.0.cfg";`
                        "policy.14.1.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy14.1.cfg";`
                        "policy.14.1.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy14.1.cfg";`
                        "policy.14.2.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy14.2.cfg";`
                        "policy.14.2.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy14.2.cfg";`
                        "policy.14.3.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy14.3.cfg";`
                        "policy.14.3.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy14.3.cfg";`
                        "policy.14.4.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy14.4.cfg";`
                        "policy.14.4.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy14.4.cfg";`
                        "policy.15.0.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy15.0.cfg";`
                        "policy.15.0.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy15.0.cfg";`
                        "policy.8.0.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy.cfg";`
                        "policy.8.0.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy.cfg";`
                        "policy.8.1.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy8.1.cfg";`
                        "policy.8.1.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy8.1.cfg";`
                        "policy.8.2.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy8.2.cfg";`
                        "policy.8.2.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy8.2.cfg";`
                        "policy.8.3.Microsoft.Exchange.Data.Common" = "Microsoft.Exchange.Data.Common.VersionPolicy8.3.cfg";`
                        "policy.8.3.Microsoft.Exchange.Data.Transport" = "Microsoft.Exchange.Data.Transport.VersionPolicy8.3.cfg"; }

        $listOfCFGs = @()
        foreach ($key in $policyDirectories.keys) {
            $listOfCFGs = $listOfCFGs + (Get-ChildItem -Recurse (Join-Path $baseDirectory $key) $policyDirectories[$key]).FullName
        }
        $count = 0;
        foreach ($cfgFile in $listOfCFGs) {
            Write-MyVerbose "Fixing $cfgFile .."
            $content = Get-Content $cfgFile
            $content -replace "[-\d+\.]*-->","-->" | Out-File $cfgFile -Force
            $count++
        }
        Write-MyOutput "Exchange2013-KB2938053-FixIt fixed $count files"
    }

    Function Exchange2013-KB2997355-FixIt {
        # Parts taken from Exchange2013-KB2997355-FixIt.ps1
        # Copyright (c) Microsoft Corporation. All rights reserved. 
        Write-MyOutput "Applying Exchange2013-KB2997355-FixIt (KB2997355, Exchange Online Mailbox Management Fix)"
        $exchangeInstallPath = get-itemproperty -path HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup -ErrorAction SilentlyContinue
        if ($exchangeInstallPath -ne $null -and (Test-Path $exchangeInstallPath.MsiInstallPath)) {
            $cfgFile = Join-Path (Join-Path $exchangeInstallPath.MsiInstallPath "ClientAccess\ecp\DDI") "RemoteDomains.xaml"

            Write-MyOutput "Updating XAML file $cfgfile ..."
            $content= Get-Content $cfgFile
            $content= $content -Replace '<Variable DataObjectName="RemoteDomain" Name="DomainName" Type="{x:Type s:String}" />','<Variable DataObjectName="RemoteDomain" Name="DomainName" Type="{x:Type s:String}" />    <Variable DataObjectName="RemoteDomain" Name="TargetDeliveryDomain" Type="{x:Type s:Boolean}" />' 
            $content= $content -Replace '<GetListWorkflow Output="Identity, Name, DomainName">','<GetListWorkflow Output="Identity, Name, DomainName, TargetDeliveryDomain">'
            $content= $content -Replace '<GetObjectWorkflow Output="Identity,Name, DomainName, AllowedOOFType, AutoReplyEnabled,AutoForwardEnabled,DeliveryReportEnabled, NDREnabled,  TNEFEnabled, MeetingForwardNotificationEnabled, CharacterSet, NonMimeCharacterSet">','<GetObjectWorkflow Output="Identity, Name, DomainName, TargetDeliveryDomain, AllowedOOFType, AutoReplyEnabled, AutoForwardEnabled, DeliveryReportEnabled, NDREnabled,  TNEFEnabled, MeetingForwardNotificationEnabled, CharacterSet, NonMimeCharacterSet">'
            $content | Out-File $cfgFile -Force
            # IISReset not required at this stage
            Write-MyOutput "Fixed XAML files"
        }
        Else {
            Write-MyError 'KB2997355: Unable to locate Exchange install path'
        }
    }

    Function Get-NETVersion {
        # 378389 = v4.5, 378758 = v4.5.1, 378675= v4.5.1/2 on WS2012R2, 379893= v4.5.2
        $NetVersion= (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
        Write-MyVerbose ".NET version installed is $NetVersion"
        return [int]$NetVersion
    }

    Function Set-NET461InstallBlock {
        Write-MyOutput "Set installation blockade for .NET Framework 4.6.1 (KB3133990)"
        $RegKey= "HKLM:\Software\Microsoft\NET Framework Setup\NDP\WU"
        $RegName= "BlockNetFramework461"
        If( -not( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue)) {
            If( -not (Test-Path $RegKey -ErrorAction SilentlyContinue)) {
                New-Item -Path (Split-Path $RegKey -Parent) -Name (Split-Path $RegKey -Leaf) -ErrorAction SilentlyContinue | out-null
            }
        }
        New-ItemProperty -Path $RegKey -Name $RegName  -Value 1 -ErrorAction SilentlyContinue| out-null
        If( -not( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue)) {
            Write-MyError "Unable to set registry entry $RegKey\$RegName"
        }
    }

    Function Remove-NET461InstallBlock {
        Write-MyOutput "Checking for installation blockade for .NET Framework 4.6.1 (KB3133990)"
        $RegKey= "HKLM:\Software\Microsoft\NET Framework Setup\NDP\WU"
        $RegName= "BlockNetFramework461"
        If( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue) {
            Write-MyOutput "Removing installation blockade for .NET Framework 4.6.1 (KB3133990)"
            Remove-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue| out-null
            If( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue) {
                Write-MyError "Unable to remove registry entry $RegKey\$RegName"
            }
        }
    }

    Function Check-Sanity {

        Write-MyOutput "Performing sanity checks .."

        Write-MyOutput "Checking temporary installation folder .."
        Mkdir $State["InstallPath"] -ErrorAction SilentlyContinue |out-null
        If( !( Test-Path $State["InstallPath"])) {
            Write-MyError "Can't create temporary folder $($State["InstallPath"])"
            Exit $ERR_CANTCREATETEMPFOLDER
        }

        Write-MyVerbose "Checking Operating System .. $($MajorOSVersion).$($MinorOSVersion)" 
        If( ($MajorOSVersion -ne $WS2012R2_MAJOR) -and ($MajorOSVersion -ne $WS2012_MAJOR) -and ($MajorOSVersion -eq $WS2008R2_MAJOR -and $MinorOSVersion -lt 7601) ) {
            Write-MyError "Windows Server 2008 R2 SP1, Windows Server 2012 or Windows Server 2012 R2 is required, but not detected"
            Exit $ERR_UNEXPECTEDOS
        }

        Write-MyOutput "Checking running mode .."
        If(! ( is-Admin)) {
            Write-MyError "Script requires running in elevated mode"
            Exit $ERR_RUNNINGNONADMINMODE
        }

        $ExOrg= Get-ExchangeOrganization
        If( $ExOrg) {
            If( $State["OrganizationName"]) {
                If( $State["OrganizationName"] -ne $ExOrg) {
                    Write-MyError "OrganizationName mismatches with discovered Exchange Organization name ($ExOrg)"
                    Exit $ERR_ORGANIZATIONNAMEMISMATCH
                }
            }
            Write-MyOutput "Exchange Organization is: $ExOrg"
        }
        Else {
            If( $State["OrganizationName"]) {
                Write-MyOutput "Exchange Organization will be: $($State['OrganizationName'])"
            }
            Else {
                Write-MyError 'OrganizationName not specified and no Exchange Organization discovered'
                Exit $ERR_MISSINGORGANIZATIONNAME
            }
        }

        If( !( $State["NoSetup"]) -or $State["OrganizationName"]) {
            Write-MyOutput "Checking if we can access Exchange setup .."
            If(! (Test-Path "$($State['SourcePath'])\setup.exe")) {
                Write-MyError "Can't find Exchange setup at $($State['SourcePath'])"
                Exit $ERR_MISSINGEXCHANGESETUP
            }
            Else {
                Write-MyOutput "Exchange setup located at $($State['SourcePath'])\setup.exe"
            }

            $SetupVersion= File-DetectVersion "$($State["SourcePath"])\Setup\ServerRoles\Common\ExSetup.exe"
            Write-MyOutput "ExSetup version: $(Setup-TextVersion $SetupVersion )"
            If( $SetupVersion) {
                $Num= $SetupVersion.split('.') | ForEach-Object { [string]([int]$_)}
                $MajorSetupVersion= [decimal]($num[0]+ '.'+ $num[1])
                $MinorSetupVersion= [decimal]($num[2]+ '.'+ $num[3])
            }
            Else {
                $MajorSetupVersion= 0
                $MinorSetupVersion= 0
            }
            $State['MajorSetupVersion'] = $MajorSetupVersion
            $State['MinorSetupVersion'] = $MinorSetupVersion

            If( $UseWMF3 -and $SetupVersion -ge $EX2013STOREEXE_SP1) {
                Write-Warning "WMF3 is not supported for Exchange Server 2013 SP1 and up"
            }
            Write-MyOutput "Checking roles to install"
            If( $State['MajorSetupVersion'] -ge $EX2016_MAJOR) {
                If ( !( $State["InstallMailbox"])) {
                    Write-MyError "No roles specified to install"
                    Exit $ERR_UNKNOWNROLESSPECIFIED
                }
                If ( $State["InstallCAS"]) {
                    Write-Warning 'Exchange 2016 setup detected, will ignore deprecated InstallCAS parameter'
                }
            }
            Else {
                If ( !( $State["InstallMailbox"]) -and !( $State["InstallCAS"])) {
                    Write-MyError "No roles specified to install"
                    Exit $ERR_UNKNOWNROLESSPECIFIED
                }
            }
        }

        Write-MyOutput "Checking domain membership status .."
        If(! ( Get-WmiObject Win32_ComputerSystem).PartOfDomain) {
            Write-MyError "System is not domain-joined"
            Exit $ERR_NOTDOMAINJOINED
        }

        Write-MyOutput "Checking NIC configuration .."
        If(! (Get-WmiObject Win32_NetworkAdapterConfiguration -Filter {IPEnabled=True and DHCPEnabled=False})) {
            Write-Warning "System doesn't have a static IP addresses configured"
        }

        If ( $State["TargetPath"]) {
            $Location= Split-Path $State['TargetPath'] -Qualifier
            Write-MyOutput "Checking installation path .."
            If( !(Test-Path $Location)) {
                Write-MyError "MDB log location unavailable: ($Location)"
                Exit $ERR_MDBDBLOGPATH
            }
        }
        If ( $State["InstallMDBLogPath"]) {
            $Location= Split-Path $State['InstallMDBLogPath'] -Qualifier
            Write-MyOutput "Checking MDB log path .."
            If( !(Test-Path $Location)) {
                Write-MyError "MDB log location unavailable: ($Location)"
                Exit $ERR_MDBDBLOGPATH
            }
        }
        If ( $State["InstallMDBDBPath"]) {
            $Location= Split-Path $State['InstallMDBLogPath'] -Qualifier
            Write-MyOutput "Checking MDB database path .."
            If( !(Test-Path $Location)) {
                Write-MyError "MDB database location unavailable: ($Location)"
                Exit $ERR_MDBDBLOGPATH
            }
        }

        Write-MyOutput "Checking Exchange Forest Schema Version"
        If( $State['MajorSetupVersion'] -ge $EX2016_MAJOR) {
            $minFFL= $EX2016_MINFORESTLEVEL
            $minDFL= $EX2016_MINDOMAINLEVEL
        }
        Else {
            $minFFL= $EX2013_MINFORESTLEVEL
            $minDFL= $EX2013_MINDOMAINLEVEL
        }
        $tmp= Get-ExchangeForestLevel
        If( $tmp) {
            Write-MyOutput "Exchange Forest Schema Version is $tmp"
        }
        Else {
            Write-MyOutput "Active Directory is not prepared"
        }
        If( $tmp -lt $minFFL) {
            If( $State["InstallPhase"] -eq 4) {
                # Only check before starting setup
                Write-MyError "Minimum required FFL version is $minFFL, aborting"
                Exit $ERR_BADFORESTLEVEL
            }
        }

        Write-MyOutput "Checking Exchange Domain Version"
        $tmp= Get-ExchangeDomainLevel
        If( $tmp) {
            Write-MyOutput "Exchange Domain Version is $tmp"
        }
        If( $tmp -lt $minDFL) {
            If( $State["InstallPhase"] -eq 4) {
                # Only check before starting setup
                Write-MyError "Minimum required DFL version is $minDFL, aborting"
                Exit $ERR_BADDOMAINLEVEL
            }
        }

        Write-MyOutput "Checking domain mode"
        If( Test-DomainNativeMode -eq $DOMAIN_MIXEDMODE) {
            Write-MyError "Domain is in mixed mode, native mode is required"
            Exit $ERR_ADMIXEDMODE
        }
        Else {
            Write-MyOutput "Domain is in native mode"
        }

        Write-MyOutput "Checking Forest Functional Level"
        If( ( Get-ForestFunctionalLevel) -lt $FOREST_LEVEL2003) {
            Write-MyError "Forest is not Functional Level 2003 or later"
            Exit $ERR_ADFORESTLEVEL
        }
        Else {
            Write-MyOutput "Forest Functional Level is 2003 or later"
        }

        If( Get-PSExecutionPolicy) {
            # Referring to http://support.microsoft.com/kb/2810617/en
            Write-Warning "PowerShell Execution Policy is configured through GPO and may prohibit Exchange Setup. Clearing entry."
            Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell -Name ExecutionPolicy -Value "" -Force
        }

        If( $State["AutoPilot"]) {
            If( $State["AdminAccount"] -and $State["AdminPassword"]) {
                Write-MyOutput "Checking provided credentials"
                If( validate-Credentials) {
                    Write-MyOutput "Credentials seem valid"
                }
                Else {
                    Write-MyError "Provided credentials don't seem to be valid"
                    Exit $ERR_INVALIDCREDENTIALS
                }
            } 
            Else {
                Try {
                    Write-MyOutput "Credentials not specified, prompting .."
                    $Credentials= Get-Credential
                    $State["AdminAccount"]= $Credentials.UserName
                    $State["AdminPassword"]= ($Credentials.Password | ConvertFrom-SecureString)
                }
                Catch {
                    Write-MyError "AutoPilot specified but no or improper credentials provided"
                    Exit $ERR_NOACCOUNTSPECIFIED
                }
            }
        }
    }

    Function Cleanup {
        Write-MyOutput "Cleaning up .."
        If( Get-WindowsFeature Bits) {
            Write-MyOutput "Removing BITS feature"
            Remove-WindowsFeature Bits
        }
        Write-MyVerbose "Removing state file $Statefile"
        Remove-Item $Statefile
    }

    Function LockScreen {
        Write-MyVerbose 'Locking system'
        rundll32.exe user32.dll,LockWorkStation
    }

    Function Configure-HighPerformancePowerPlan {
        Write-MyVerbose 'Configuring Power Plan'
        $p = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'High Performance'"          
        $tmp= Invoke-CimMethod -InputObject $p -MethodName Activate        
        $CurrentPlan = Get-WmiObject -Namespace root\cimv2\power -Class win32_PowerPlan | Where-Object { $_.IsActive }
        Write-MyOutput "Power Plan active: $($CurrentPlan.ElementName)"
    }

    Function Configure-Pagefile {
        Write-MyVerbose 'Checking Pagefile Configuration'
        $CS = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
        If ($CS.AutomaticManagedPagefile) {
            Write-MyVerbose 'System configured to use Automatic Managed Pagefile, reconfiguring'
            Try {
                $CS.AutomaticManagedPagefile = $false
                # RAM + 10 MB, with maximum of 32GB + 10MB
                $InstalledMem= $CS.TotalPhysicalMemory
                $DesiredSize= (($InstalledMem + 10MB), (32GB+10MB)| Measure-Object -Minimum).Minimum / 1MB
                $tmp= $CS.Put()
                $CPF= Get-WmiObject -Class Win32_PageFileSetting
                $CPF.InitialSize= $DesiredSize
                $CPF.MaximumSize= $DesiredSize
                $tmp= $CPF.Put()
            }
            Catch {
                Write-MyError "Problem reconfiguring pagefile: $($ERROR[0])"
            }
            $CPF= Get-WmiObject -Class Win32_PageFileSetting
            Write-MyOutput "Pagefile set to manual, initial/maximum size: $($CPF.InitialSize)MB / $($CPF.MaximumSize)MB" 
        }
        Else {
            Write-MyVerbose 'Manually configured page file, skipping configuration'
        }
    }

    Function Configure-TCP {
        # See https://blogs.technet.microsoft.com/david231/2015/03/30/for-exchange-2010-and-2013-do-this-before-calling-microsoft/
        Write-MyVerbose 'Configuring RPC Timeout setting'
        $RegKey= "HKLM:\Software\Policies\Microsoft\Windows NT\RPC"
        $RegName= "MinimumConnectionTimeout"
        If( -not( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue)) {
            If( -not (Test-Path $RegKey -ErrorAction SilentlyContinue)) {
                New-Item -Path (Split-Path $RegKey -Parent) -Name (Split-Path $RegKey -Leaf) -ErrorAction SilentlyContinue | out-null
            }
        }
        Write-MyOutput 'Setting RPC Timeout to 120 seconds'
        New-ItemProperty -Path $RegKey -Name $RegName  -Value 120 -ErrorAction SilentlyContinue| out-null

        Write-MyVerbose 'Configuring Keep-Alive Timeout setting'
        $RegKey= "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        $RegName= "KeepAliveTime"
        If( -not( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue)) {
            If( -not (Test-Path $RegKey -ErrorAction SilentlyContinue)) {
                New-Item -Path (Split-Path $RegKey -Parent) -Name (Split-Path $RegKey -Leaf) -ErrorAction SilentlyContinue | out-null
            }
        }
        Write-MyOutput 'Setting Keep-Alive Timeout to 120 seconds'
        New-ItemProperty -Path $RegKey -Name $RegName  -Value 120 -ErrorAction SilentlyContinue| out-null
    }

    Function Disable-SSL3 {
        # SSL3 disabling/Poodle, https://support.microsoft.com/en-us/kb/187498
        Write-MyVerbose 'Disabling SSL3 protocol for services'
        $RegKey= "HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
        $RegName= "Enabled"
        If( -not( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue)) {
            If( -not (Test-Path $RegKey -ErrorAction SilentlyContinue)) {
                New-Item -Path (Split-Path $RegKey -Parent) -Name (Split-Path $RegKey -Leaf) -ErrorAction SilentlyContinue | out-null
            }
        }
        $RegKey= "HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
        $RegName= "DisabledByDefault"
        If( -not( Get-ItemProperty -Path $RegKey -Name $RegName -ErrorAction SilentlyContinue)) {
            If( -not (Test-Path $RegKey -ErrorAction SilentlyContinue)) {
                New-Item -Path (Split-Path $RegKey -Parent) -Name (Split-Path $RegKey -Leaf) -ErrorAction SilentlyContinue | out-null
            }
        }
        New-ItemProperty -Path $RegKey -Name $RegName  -Value 1 -ErrorAction SilentlyContinue| out-null
    }

    ########################################
    # MAIN
    ########################################

    #Requires -Version 2.0

    $ScriptFullName = $MyInvocation.MyCommand.Path
    $ScriptName = $ScriptFullName.Split("\")[-1]
    $ParameterString= $PSBoundParameters.getEnumerator() -join " "
    $MajorOSVersion= [string](Get-WmiObject Win32_OperatingSystem | Select-Object @{n="Major";e={($_.Version.Split(".")[0]+"."+$_.Version.Split(".")[1])}}).Major
    $MinorOSVersion= [string](Get-WmiObject Win32_OperatingSystem | Select-Object @{n="Minor";e={($_.Version.Split(".")[2])}}).Minor

    # PoSHv2 Workaround
    If( $InstallMultiRole) {
		$InstallCAS= $true
		$InstallMailbox= $true
    }

    $State=@{}
    $StateFile= "$InstallPath\$($ScriptName)_state.xml"
    $State= Load-State

    Write-Output "Script $ScriptFullName called using $ParameterString"
    Write-Output "Using parameterSet $($PsCmdlet.ParameterSetName)"
    Write-Output "Running on OS build $MajorOSVersion.$MinorOSVersion"

    If(! $State.Count) {
        # No state, initialize settings from parameters
        If( $($PsCmdlet.ParameterSetName) -eq "AutoPilot") {
            Write-Error "Running in AutoPilot mode but no state file present"
            Exit $ERR_AUTOPILOTNOSTATEFILE
        }

        $State["InstallMailbox"]= $InstallMailbox
        $State["InstallCAS"]= $InstallCAS
        $State["InstallMultiRole"]= $InstallMultiRole
        $State["InstallMDBDBPath"]= $MDBDBPath
        $State["InstallMDBLogPath"]= $MDBLogPath
        $State["InstallMDBName"]= $MDBName
        $State["InstallPath"]= $InstallPath
        $State["InstallPhase"]= 0
        $State["OrganizationName"]= $Organization
        $State["AdminAccount"]= $Credentials.UserName
        $State["AdminPassword"]= ($Credentials.Password | ConvertFrom-SecureString -ErrorAction SilentlyContinue)
        $State["SourcePath"]= $SourcePath
        $State["SetupVersion"]= ( File-DetectVersion "$($State["SourcePath"])\setup.exe")
        $State["TargetPath"]= $TargetPath
        $State["AutoPilot"]= $AutoPilot
        $State["IncludeFixes"]= $IncludeFixes
        $State["InstallFilterPack"]= $InstallFilterPack
        $State["NoSetup"]= $NoSetup
        $State["UseWMF3"]= $UseWMF3
        $State["NoNet461"]= $NoNet461
        $State["Install461"]= $False
        $State["DisableSSL3"]= $DisableSSL3
        $State["SCP"]= $SCP
        $State["Lock"]= $Lock
        $State["TranscriptFile"]= "$($State["InstallPath"])\$($ScriptName)_$(Get-Date -format "yyyyMMddHHmmss").log"
        $State["Verbose"]= $VerbosePreference
    }

    If( $State["Lock"] ) {
        LockScreen
    }

    # Allow overruling of phase from command line
    If( $Phase -ne 0) {
        $State["InstallPhase"]= $Phase
    }

    # When skipping setup, limit no. of steps
    If( $State["NoSetup"]) {
        $MAX_PHASE = 3
    }
    Else {
        $MAX_PHASE = 6
    }

    # (Re)activate verbose setting (so settings becomes effective after reboot)
    If( $State["Verbose"].Value) {
        $VerbosePreference= $State["Verbose"].Value.ToString()
    }

    If( $AutoPilot -and $State["InstallPhase"] -gt 0) {
        # Wait a little before proceeding 
        Write-MyOutput "Will continue unattended installation of Exchange in $COUNTDOWN_TIMER seconds .."
        Start-Sleep -Seconds $COUNTDOWN_TIMER
    }

    Check-Sanity

    Write-MyVerbose "Logging to $($State["TranscriptFile"])"

    # Get rid of the security dialog when spawning exe's etc.
    Disable-OpenFileSecurityWarning

    # Always disable autologon allowing you to "fix" things and reboot intermediately
    Disable-AutoLogon

    Write-MyOutput "Checking for pending reboot .."
    #If( is-RebootPending ) {
    If( $false){
        If( $State["AutoPilot"]) {
            Write-Warning "Reboot pending, will reboot system and rerun phase"
        }
        Else {
            Write-MyError "Reboot pending, please reboot system and restart script (parameters will be saved)"
        }
    }
    Else {

    $State["InstallPhase"]++
    Write-MyVerbose "Current phase is $($State["InstallPhase"]) of $MAX_PHASE"

      Switch ($State["InstallPhase"]) {
        1 {
            Write-MyOutput "Installing Operating System prerequisites"
            Install-WindowsFeatures $MajorOSVersion

            If( @($WS2008R2_MAJOR, $WS2012_MAJOR, $WS2012R2_MAJOR) -contains $MajorOSVersion) {
 
                $TempInstall461= $False
                If( ($State["MajorSetupVersion"] -ge $EX2016_MAJOR -and (is-MinimalBuild $State["SetupVersion"] $EX2016STOREEXE_CU2)) -or 
                    ($State["MajorSetupVersion"] -eq $EX2013_MAJOR -and (is-MinimalBuild $State["SetupVersion"] $EX2013STOREEXE_CU13))) {
                    If( $State["NoNet461"]) {
                        Write-MyOutput ".NET Framework 4.6.1 supported, but NoNet461 specified - will use .NET Framework 4.5.2"
                    }
                    Else {
                        Write-MyOutput "Exchange setup version ($($State["SetupVersion"])) supports .NET Framework 4.6.1"
                        $State["Install461"]= $True
                    }
                }
                Else {
                    If( $State["NoNet461"]) {
                        Write-MyWarning "Ignoring NoNet461 switch: Exchange version doesn't support .NET Framework 4.6.1"
                    }
                    Else {
                        Write-MyOutput "Exchange setup version ($($State["SetupVersion"])) doesn't support .NET Framework 4.6.1"
                    }
                }

                If( $State["Install461"]) {
                    # Install hotfixes required by .NET Framework 4.6.1
                    Switch( $MajorOSVersion) {
                        $WS2008R2_MAJOR {
                        }
                        $WS2012_MAJOR {
                        }
                        $WS2012R2_MAJOR {
                            Package-Install "KB2919442" "KB2919442: Update for Windows Server 2012 R2" "Windows8.1-KB2919442-x64.msu" "https://download.microsoft.com/download/D/6/0/D60ED3E0-93A5-4505-8F6A-8D0A5DA16C8A/Windows8.1-KB2919442-x64.msu" ("/quiet", "/norestart")
                            Package-Install "KB2919355" "Windows RT 8.1, Windows 8.1, and Windows Server 2012 R2 update: April 2014" "Windows8.1-KB2919355-x64.msu" "https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2919355-x64.msu" ("/quiet", "/norestart")
                        }
                    }
                }
            }
        }

        2 {
            Write-MyOutput "Installing Exchange prerequisites"
            Import-Module BITSTransfer

            If( $State["InstallFilterPack"]) {
                Package-Install "{95140000-2000-0409-1000-0000000FF1CE}" "Microsoft Office 2010 Filter Pack" "FilterPack64bit.exe" "http://download.microsoft.com/download/0/A/2/0A28BBFA-CBFA-4C03-A739-30CCA5E21659/FilterPack64bit.exe" ("/passive", "/norestart")
                Package-Install "00004159000290400100000000F01FEC\Patches\2B24AAAA46EAEB942BF5566A6B1DE170" "Microsoft Office 2010 Filter Pack SP1" "filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe" "http://download.microsoft.com/download/A/A/3/AA345161-18B8-45AE-8DC8-DA6387264CB9/filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe" ("/passive", "/norestart")
            }

            If( $State["Install461"]) {
                # Check .NET FrameWork 4.6.1 or later installed
                If( (Get-NETVersion) -lt 394271) {
                    # If present, remove blockade
                    Remove-NET461InstallBlock
                    Package-Install "KB3102467" "Microsoft .NET Framework 4.6.1" "NDP461-KB3102436-x86-x64-AllOS-ENU.exe" "https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe" ("/q", "/norestart")
                }
                Else {
                    Write-MyOutput ".NET Framework 4.6.1 or later detected"
                }
                # For .NET 4.6.1, install required hotfixes: KB3146716 for WS2008/WS2008R2, KB3146714 for WS2012, and KB3146715 for WS2012R2
                Write-MyOutput "Checking applicable post-.NET Framework 4.6.x hotfixes" 
                Switch( $MajorOSVersion) {
                    $WS2008R2_MAJOR {
                        Package-Install "KB3146716" "Hotfix rollup 3146716 for the .NET Framework 4.6 and 4.6.1 in Windows" "NDP461-KB3146716-x86-x64-ENU.exe" "http://download.microsoft.com/download/E/F/1/EF1FB34B-58CB-4568-85EC-FA359387E328/NDP461-KB3146716-x86-x64-ENU.exe" ("/quiet", "/norestart")
                    }
                    $WS2012_MAJOR {
                        Package-Install "KB3146714" "Hotfix rollup 3146714 for the .NET Framework 4.6 and 4.6.1 in Windows" "Windows8-RT-KB3146714-x64.msu" "http://download.microsoft.com/download/E/F/1/EF1FB34B-58CB-4568-85EC-FA359387E328/Windows8-RT-KB3146714-x64.msu" ("/quiet", "/norestart")
                    }
                    $WS2012R2_MAJOR {
                        Package-Install "KB3146715" "Hotfix rollup 3146715 for the .NET Framework 4.6 and 4.6.1 in Windows" "Windows8.1-KB3146715-x64.msu" "http://download.microsoft.com/download/E/F/1/EF1FB34B-58CB-4568-85EC-FA359387E328/Windows8.1-KB3146715-x64.msu" ("/quiet", "/norestart")
                    }
                }
            }
            Else {
                # Check .NET FrameWork 4.5.2 or later installed
                If( (Get-NETVersion) -lt 379893) {
                    Write-MyOutput ".NET Framework 4.5.2 will be installed"
                    # Package GUID is different for WS2008R2/2012, .452 supported on CU7 or later
                    If( $State["SetupVersion"] -ge $EX2013STOREEXE_CU7) {
                        If( $MajorOSVersion -eq $WS2008R2_MAJOR) {
                            Package-Install "{26784146-6E05-3FF9-9335-786C7C0FB5BE}" "Microsoft .NET Framework 4.5.2" "NDP452-KB2901907-x86-x64-AllOS-ENU.exe" "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe" ("/q", "/norestart")
                        }
                        Else {
                            Package-Install "KB2934520" "Microsoft .NET Framework 4.5.2" "NDP452-KB2901907-x86-x64-AllOS-ENU.exe" "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe" ("/q", "/norestart")
                        }
                    } 
                    Else {
                        If( (Get-NETVersion) -lt 378675) {
                            If( $MajorOSVersion -eq $WS2008R2_MAJOR) {
                                Package-Install "{7DEBE4EB-6B40-3766-BB35-5CBBC385DA37}" "Microsoft .NET Framework 4.5.1" "NDP451-KB2858728-x86-x64-AllOS-ENU.exe" "http://download.microsoft.com/download/1/6/7/167F0D79-9317-48AE-AEDB-17120579F8E2/NDP451-KB2858728-x86-x64-AllOS-ENU.exe" ("/q", "/norestart")
                            }
                            Else {
                                Package-Install "KB2881468" "Microsoft .NET Framework 4.5.1" "NDP451-KB2858728-x86-x64-AllOS-ENU.exe" "http://download.microsoft.com/download/1/6/7/167F0D79-9317-48AE-AEDB-17120579F8E2/NDP451-KB2858728-x86-x64-AllOS-ENU.exe" ("/q", "/norestart")
                            }
                        }
                        Else {
                            Write-MyOutput ".NET Framework 4.5.1 or later detected"
                        }
                    }
                }
                Else {s
                    Write-MyOutput ".NET Framework 4.5.2 or later detected"
                }
                Set-NET461InstallBlock
            }

            If( $MajorOSVersion -eq $WS2008R2_MAJOR) {
                If( $State["UseWMF3"]) {
                    Package-Install "KB2506143" "Windows Management Framework 3.0" "Windows6.1-KB2506143-x64.msu" "http://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.1-KB2506143-x64.msu" ("/quiet", "/norestart")
                } Else {
                    Package-Install "KB2819745" "Windows Management Framework 4.0" "Windows6.1-KB2819745-x64-MultiPkg.msu" "http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu" ("/quiet", "/norestart")
                }
                Package-Install "KB974405" "KB974405: Windows Identity Foundation" "Windows6.1-KB974405-x64.msu" "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu" ("/quiet", "/norestart")
                Package-Install "KB2619234" "KB2619234: Enable Association Cookie/GUID used by RPC/HTTP to also be used at RPC layer" "Windows6.1-KB2619234-v2-x64.msu|437879_intl_x64_zip.exe" "http://hotfixv4.microsoft.com/Windows 7/Windows Server2008 R2 SP1/sp2/Fix381274/7600/free/437879_intl_x64_zip.exe" ("/quiet", "/norestart")
                Package-Install "KB2758857" "KB2758857: Insecure library loading could allow remote code execution (supersedes KB2533623)" "Windows6.1-KB2758857-x64.msu" "http://download.microsoft.com/download/A/9/1/A91A39EA-9BD8-422F-A018-44CD62CA7485/Windows6.1-KB2758857-x64.msu" ("/quiet", "/norestart")
            }

            If( $MajorOSVersion -eq $WS2012_MAJOR) {
                Package-Install "KB2985459" "KB2985459: The W3wp.exe process has high CPU usage when you run PowerShell commands for Exchange" "Windows8-RT-KB2985459-x64.msu|477081_intl_x64_zip.exe" "http://hotfixv4.microsoft.com/Windows%208/Windows%20Server%202012%20RTM/nosp/Fix512067/9200/free/477081_intl_x64_zip.exe" ("/quiet", "/norestart")
                Package-Install "KB2884597" "KB2884597: Virtual Disk Service or applications that use the Virtual Disk Service crash or freeze in Windows Server 2012" "Windows8-RT-KB2884597-x64.msu|467323_intl_x64_zip.exe" "hotfixv4.microsoft.com/Windows%208%20RTM/nosp/Fix469260/9200/free/467323_intl_x64_zip.exe" ("/quiet", "/norestart")
                Package-Install "KB2894875" "KB2894875: Windows 8-based or Windows Server 2012-based computer freezes when you run the 'dir' command on an ReFS volume" "Windows8-RT-KB2894875-x64.msu|468889_intl_x64_zip.exe" "http://hotfixv4.microsoft.com/Windows%208%20RTM/nosp/Fix473391/9200/free/468889_intl_x64_zip.exe" ("/quiet", "/norestart")
            }

        }

        3 {
            Write-MyOutput "Installing Exchange prerequisites (continued)"
            Package-Install "{41D635FE-4F9D-47F7-8230-9B29D6D42D31}" "Unified Communications Managed API 4.0 Runtime" "UcmaRuntimeSetup.exe" "http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe" ("/passive", "/norestart")

            If ($State["OrganizationName"]) {
                Write-MyOutput "Checking/Preparing Active Directory"
                Prepare-Exchange
            }
        }

        4 {
            Write-MyOutput "Installing Exchange"
            Install-Exchange15_
            If( Get-Service MSExchangeTransport -ErrorAction SilentlyContinue) {
                Write-MyOutput "Configuring MSExchangeTransport startup to Manual"
                Set-Service MSExchangeTransport -StartupType Manual
            }
            If( Get-Service MSExchangeFrontEndTransport -ErrorAction SilentlyContinue) {
                Write-MyOutput "Configuring MSExchangeFrontEndTransport startup to Manual"
                Set-Service MSExchangeFrontEndTransport -StartupType Manual
            }
            switch( $State["SCP"]) {
                ''      {
                        # Do nothing
                }
                $null   {
                            Write-MyOutput 'Removing Service Connection Point record'
                            Clear-AutodiscoverServiceConnectionPoint $ENV:COMPUTERNAME
                }
                default {
                            Write-MyOutput "Configuring Service Connection Point record as $($State['SCP'])"
                            Set-AutodiscoverServiceConnectionPoint $ENV:COMPUTERNAME $State['SCP']
                }
            }
        }

        5 {
            Write-MyOutput "Post-configuring"

            Configure-HighPerformancePowerPlan
            Configure-Pagefile
            Configure-TCP
            If( $State["DisableSSL3"]) {
                Disable-SSL3
            }

            #Load-ExchangeModule

            If( $State["InstallMailbox"] ) {
                If ( $State["InstallFilterPack"]) {
                    Enable-IFilters
                }
                # Insert other Mailbox Server specifics here
            }
 		    If( $State["InstallCAS"]) {
                # Insert Client Access Server specifics here
            }
            # Insert generic customizations here

            #If( Get-Service MSExchangeHM -ErrorAction SilentlyContinue) {
            #    Write-MyOutput "Configuring MSExchangeHM startup to Manual"
            #    Set-Service MSExchangeHM -StartupType Manual
            #}

            If( $State["IncludeFixes"]) {
              Write-MyOutput "Installing applicable recommended hotfixes and security updates"

              $ImagePathVersion= File-DetectVersion ( (Get-WMIObject -Query 'select * from win32_service where name="MSExchangeServiceHost"').PathName.Trim('"') )
              Write-MyVerbose "Installed Exchange MSExchangeIS version is $(Setup-TextVersion $ImagePathVersion)"

              Switch( $MajorOSVersion) {
                $WS2008R2_MAJOR {
                    # WS2008R2
                }
                $WS2012_MAJOR {
                    # WS2012
                }
                $WS2012R2_MAJOR {
                    # WS2012R2
                }
              }

              Switch( $ImagePathVersion) {
                $EX2013STOREEXE_CU2 {
                    Package-Install "KB2880833" "Security Update For Exchange Server 2013 CU2" "Exchange2013-KB2880833-x64-en.msp" "http://download.microsoft.com/download/3/D/A/3DA5AC0D-4B94-479E-957F-C7C66DE1B30F/Exchange2013-KB2880833-x64-en.msp" ("/passive", "/norestart")
                }
                $EX2013STOREEXE_CU3 {                
                    Package-Install "KB2880833" "Security Update For Exchange Server 2013 CU3" "Exchange2013-KB2880833-x64-en.msp" "http://download.microsoft.com/download/0/E/3/0E3FFD83-FE6A-48B7-85F2-3EF92155EFBE/Exchange2013-KB2880833-x64-en.msp" ("/passive", "/norestart")
                }
                $EX2013STOREEXE_SP1 {
                    Exchange2013-KB2938053-FixIt
                }
                $EX2013STOREEXE_CU5 {
                    DisableSharedCacheServiceProbe
                }
                $EX2013STOREEXE_CU6 {
                    Exchange2013-KB2997355-FixIt
                }

                default {

                }
              }
            }
        }

        6 {
            If( Get-Service MSExchangeTransport -ErrorAction SilentlyContinue) {
                Write-MyOutput "Configuring MSExchangeTransport startup to Automatic"
                Set-Service MSExchangeTransport -StartupType Automatic
            }
            If( Get-Service MSExchangeFrontEndTransport -ErrorAction SilentlyContinue) {
                Write-MyOutput "Configuring MSExchangeFrontEndTransport startup to Automatic"
                Set-Service MSExchangeFrontEndTransport -StartupType Automatic
            }
            Enable-UAC
            Enable-IEESC
            Write-MyOutput "Setup finished - We're good to go."
        }

        default {
            Write-MyError "Unknown phase ($($State["InstallPhase"]) of $MAX_PHASE)"
        }
      }
    }

    Enable-OpenFileSecurityWarning
    Save-State $State

    If( $State["AutoPilot"]) {
        If( $State["InstallPhase"] -lt $MAX_PHASE) {
        	Write-MyVerbose "Preparing system for next phase"
	        Disable-UAC
            Disable-IEESC
            Enable-AutoLogon
            Enable-RunOnce
        }
        Else {
            Cleanup
        }
        Write-MyOutput "Rebooting in $COUNTDOWN_TIMER seconds .."
        Start-Sleep -Seconds $COUNTDOWN_TIMER
        Restart-Computer -Force
    }
    Exit $ERR_OK

} #Process