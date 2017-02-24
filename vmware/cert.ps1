Set-Location -Path "$env:HOMEDRIVE\depot\content\dlg_VC55U3D\ssl-certificate-updater-tool-1308332\requests"
$csrs = Get-ChildItem -Recurse -Path *.csr


$rootCA = 'sv-app02.hego.intra'
#$SubCA = "subca01.contoso.local"

# Online Microsoft CA name that will issue the certificates.
# Ignore if you don't have online Microsoft CAs.  
$ISSUING_CA = 'sv-app02\Hego-SV-APP01-CA'

# Your VMware CA certificate template name (not the display name; no spaces)
# Ignore if you don't have online Microsoft CAs. 
$Template = 'CertificateTemplate:View-Webserver'

   # initialize objects to use for external processes
    $psi = New-Object -TypeName System.Diagnostics.ProcessStartInfo
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $process = New-Object -TypeName System.Diagnostics.Process
    $process.StartInfo = $psi

    $csrs  | ForEach-Object {

        # submit the CSR to the CA
        $psi.FileName = 'certreq.exe'
        $psi.Arguments = @("-submit -attrib `"$Template`" -config `"$ISSUING_CA`" -f `"$_`" `"$_.DirectoryName\rui.crt`"")
	    Write-Verbose -Message "Submitting certificate request for $Service"
        $null = $process.Start()

        $cmdOut = $process.StandardOutput.ReadToEnd()
        if ($cmdOut.Trim() -like '*request is pending*')
        {
            # Output indicates the request requires approval before we can download the signed cert.
            $Script:CertsWaitingForApproval = $true

            # So we need to save the request ID to use later once they're approved.
            $reqID = ([regex]'RequestId: (\d+)').Match($cmdOut).Groups[1].Value
            if ($reqID.Trim() -eq [String]::Empty)
            {
                write-error -Message 'Unable to parse RequestId from output.'
                write-debug -Message $cmdOut
                Exit
            }
            Write-Verbose -Message "RequestId: $reqID is pending"

            # Save the request ID to a file that OnlineMintResume can read back in later
            $reqID | out-file -FilePath "$Cert_Dir\$Service\requestid.txt"
        }
        else
        {
            # Output doesn't indicate a pending request, so check for a signed cert file
            if (!(Test-Path -Path $Cert_Dir\$Service\rui.crt)) {
                Write-Error -Message 'Certificate request failed or was unable to download the signed certificate.'
                Write-Error -Message 'Verify that the ISSUING_CA variable is set correctly.' 
                Write-Debug -Message $cmdOut
                Exit
            }
        }

    }