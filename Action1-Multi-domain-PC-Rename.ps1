# ================================
# Action1 – Multi-domain PC Rename
# ================================
# Parameters expected from Action1:
#   ${NewComputerName}  - New hostname to apply
#   ${DomainUser}       - Domain account with rights to rename computers
#   ${DomainPassword}   - Password for the domain account (secure)
#   ${DomainName}       - (Optional) Domain FQDN, only needed if DomainUser does not include it
#
# Requirements:
#   - Account must be at least "Account Operators" or have delegated rights on the OU
#   - No reboot here (Action1 handles it)
# ================================

# Validate new computer name
if ([string]::IsNullOrWhiteSpace(${NewComputerName})) {
    Write-Error "No computer name provided. Aborting."
    exit 1
}

# Build credential object
$securePass = ConvertTo-SecureString ${DomainPassword} -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential (${DomainUser}, $securePass)

# Optional: check current domain
try {
    $currentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
    Write-Output "Current domain detected: $currentDomain"
}
catch {
    Write-Output "Unable to detect current domain. Continuing anyway."
}

# Attempt rename
try {
    Rename-Computer -NewName ${NewComputerName} -DomainCredential $cred -Force
    Write-Output "Computer successfully renamed to: ${NewComputerName}"
    exit 0
}
catch {
    Write-Error "Rename failed: $_"
    exit 1
}
