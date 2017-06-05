#requires -Version 2
function connect-exserver
{
    param
    (
        [String]
        [Parameter(Mandatory = $true)]
        $server
    )
    
    $exsession = New-PSSession      -ConfigurationName 'Microsoft.Exchange' 
    -ConnectionUri "http://$server/Powershell" 
    -Credential (Get-Credential) 
    -Authentication Kerberos
    Import-PSSession -Session $exsession
}
