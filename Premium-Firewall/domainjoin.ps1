# Set DNS Client Server Address to connect to the domain

$ErrorActionPreference = 'Stop'

Write-Host "Setting the DNS Client server address"

$ii = (Get-NetIPAddress -InterfaceAlias "Ethernet*" -AddressFamily IPV4).InterfaceIndex

Set-DnsClientServerAddress -InterfaceIndex $ii -ServerAddresses "10.2.0.4"

Write-Host "Adding the computer to the domain"

try {

    # Define Credentials
    [string]$userName = "burugadda\windcadmin"
    [string]$userPassword = 'DcP@$$w0rD2021*'

    # Create credential Object
    [SecureString]$secureString = $userPassword | ConvertTo-SecureString -AsPlainText -Force 
    [PSCredential]$domaincreds = New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $secureString

    $null = Add-Computer -DomainName "burugadda.local" -Credential $domaincreds

    Write-Host "Computer has joined the domain"

    # Add Domain Users to Remote Desktop Users group

    Write-Host "Adding Domain users to RDU Group"

    Add-LocalGroupMember -Group "Remote Desktop Users" -Member "burugadda.local\Domain Users"

}
catch {
    Write-Host "Message: $($_.Exception.Message)" 
}

# Install software with Chocolatey

# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# choco install googlechrome notepadplusplus vscode -y





