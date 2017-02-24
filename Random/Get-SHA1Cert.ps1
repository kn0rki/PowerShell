# Get-LANCert
#
# User Pipeline for list of Hostnames or IP-Addresses
#
# Pending: Check Revocation  http://poshcode.org/1633
# Pending: Check Issuer      http://poshcode.org/1633
# Pending: Check CN/SAN-Name
# Pending: Parallelisierung

[cmdletbinding()]
param (
    [parameter(ValueFromPipeline=$True)]
    [string]$remotehost = "localhost",
    $portrange=443,
    $tcptimeout= 1000   # wait up to 1Sec for TCP Connection
)


begin {
    set-psdebug -strict
    write-host "Get-LANCert: Start"
}

process {
    write-host "------------- Get-LANCert:Processing $remotehost"
    
    if ($remotehost.indexof(":") -ge 0) {
        write-host " Splitting Host and Port"
        $computername = $remotehost.split(":")[0]
        $portrange = $remotehost.split(":")[1]
    }
    else {
        write-host " Using PortRange"
        $computername = $remotehost
    }

    write-host " Iteration PortRange $portrange"
    foreach ($computerport in $portrange) {
        write-host " Init Result"
        $result = "" | select-object Computername,Port,Status,CN,Subject,NotAfter,NotBefore,Issuer,Thumbprint,SerialNumber,SignatureAlgorithmFriendlyName
        $result.Computername = $computername
        $result.Port = $computerport
        $result.Status = $null
        #Create a TCP Socket to the computer and a port number
        $tcpsocket = New-Object Net.Sockets.TcpClient
        try {
            write-host " Connect to $($computername):$computerport" -nonewline
            #$tcpsocket.Connect($computername, $computerport) 
            $asyncConnect = $tcpsocket.BeginConnect($computername, $computerport,$null,$null) 
            # wait up to tcptimeout
            if ($asyncConnect.AsyncWaitHandle.WaitOne($tcptimeout, $False)) {
            }
        }
        catch {
            write-host $_.Exception.Message
            $result.Status = "ErrConnect"
        }

        #test if the socket got connected
        if(!$tcpsocket.connected) {
            write-host " Unable to connect" -foregroundcolor red
            $result.Status = "NoConnection"
        }
        else {
            write-host " Connected" -ForegroundColor Green
            write-host " Get TCP-Stream"
            $tcpstream = $tcpsocket.GetStream()
            write-host " Get SSL-Stream"
            $sslStream = New-Object System.Net.Security.SslStream($tcpstream,$false,{$true})  # verification callback always true
            #$sslStream
            try {
                write-host " AuthenticateAsClient" -nonewline
                $sslStream.AuthenticateAsClient($computerName)
                write-host " HandshakeOK" -ForegroundColor green
            }
            catch {
                write-host " AuthFail" -ForegroundColor Yellow
                $result.Status = "AuthFail"
            }
           
            if ($result.Status -eq $null) {
                try {
                    Write-host " Read the certificate" -nonewline
                    $certinfo = New-Object system.security.cryptography.x509certificates.x509certificate2($sslStream.RemoteCertificate)
                    write-host "done"
                } 
                catch {
                    Write-host " Unable to read Certificate"
                }
                #$certinfo
                write-host "  Parsing Certificate Data"
                $result.Subject = $certinfo.Subject
                $result.CN = $certinfo.Subject.split(",") | where {$_.startswith("CN=")}
                Write-host "    CN= $($result.CN)"
                $result.NotAfter = $certinfo.NotAfter
                $result.NotBefore = $certinfo.NotBefore
                $result.Issuer = $certinfo.Issuer
                $result.Thumbprint = $certinfo.Thumbprint
                $result.SerialNumber = $certinfo.SerialNumber
                $result.SignatureAlgorithmFriendlyName = $certinfo.SignatureAlgorithm.FriendlyName

                if ($result.SignatureAlgorithmFriendlyName -eq "SHA1RSA") {
                    $result.Status = "WarnSHA1"
                }
                elseif (( ($result.NotAfter) - (get-date)).totaldays -lt 0 ) {
                    $result.Status = "Expired"
                }
                elseif (( ($result.NotAfter) - (get-date)).totaldays -lt 30 ) {
                    $result.Status = "Warn30Day"
                }
                else {
                    $result.Status = "OK"
                }
            }
        } 
        write-host "  Closing Connection"
        $tcpsocket.close()
        write-host "  Sending Result to Pipeline"
        $result
        write-host "  Done"
    }
}

end {
    write-host "Get-LANCert:End"
}
