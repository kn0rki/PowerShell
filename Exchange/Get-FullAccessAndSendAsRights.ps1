#Exchange get-FullAcessSendAsRights
#Gets the Accounts with FullAccess / SendAS Rights for each mailbox

$mailboxes = get-mailbox
$mailboxes |% {
	echo "USER:$_ -----"
	ADPERMS = $_ |get-adpermission |?{ $_.ExtendedRights.RawIdentity -eq "Send-As"}
	$MAILBOXPERMS = $_ | Get-MailboxPermission |? {$_.AccessRights -eq "FullAccess"}
	
	echo "ADPERMS: $_ -----"
	$ADPERMS |ft -autosize
	
	echo "MAILBOXPERMS:$_ -----"
	$MAILBOXPERMS | ft -autosize
	echo "/USER:$_ -----"
}
