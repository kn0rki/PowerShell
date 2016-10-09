#requires -Version 1
#Exchange get-FullAcessSendAsRights
#Gets the Accounts with FullAccess / SendAS Rights for each mailbox

$mailboxes = get-mailbox
$mailboxes |ForEach-Object -Process {
    Write-Output -InputObject "USER:$_ -----"
    $ADPERMS = $_ |
    get-adpermission |
    Where-Object -FilterScript {
        $_.ExtendedRights.RawIdentity -eq 'Send-As'
    }
    $MAILBOXPERMS = $_ |
    Get-MailboxPermission |
    Where-Object -FilterScript {
        $_.AccessRights -eq 'FullAccess'
    }
	
    Write-Output -InputObject "ADPERMS: $_ -----"
    $ADPERMS |Format-Table -AutoSize
	
    Write-Output -InputObject "MAILBOXPERMS:$_ -----"
    $MAILBOXPERMS | Format-Table -AutoSize
    Write-Output -InputObject "/USER:$_ -----"
}
