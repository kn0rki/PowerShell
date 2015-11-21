#Exchange get-FullAcessSendAsRights
#Gets the Accounts with FullAccess / SendAS Rights for each mailbox

$mailboxes = get-mailbox
$mailboxes |% {
	Write-Output "USER:$_ -----"
	ADPERMS = $_ |get-adpermission |Where-Object{ $_.ExtendedRights.RawIdentity -eq 'Send-As'}
	$MAILBOXPERMS = $_ | Get-MailboxPermission |Where-Object {$_.AccessRights -eq 'FullAccess'}
	
	Write-Output "ADPERMS: $_ -----"
	$ADPERMS |Format-Table -autosize
	
	Write-Output "MAILBOXPERMS:$_ -----"
	$MAILBOXPERMS | Format-Table -autosize
	Write-Output "/USER:$_ -----"
}