<#
.SYNOPSIS
    Starts a debug VM with specified VHDX and ISO, then waits for SSH availability.

.DESCRIPTION
    This script resizes the specified VHDX file to 20GB, creates a new Hyper-V VM with the given name,
    attaches the VHDX and ISO, starts the VM, and waits until the VM is accessible via SSH on port 22.
    It checks network neighbors for the VM's IP address and verifies SSH connectivity.

.PARAMETER VMName
    The name of the VM to create and start. Default is "debug".

.PARAMETER VHDXPath
    The path to the VHDX file to use for the VM. Default is ".\alpine-openstack.vhdx".

.PARAMETER ISOPath
    The path to the ISO file to attach as a DVD drive. Default is ".\seed.iso".

.PARAMETER CheckOnly
    If specified, performs a dry run without actually creating or starting the VM.

.EXAMPLE
    PS C:\> .\Start-DebugVM.ps1 -VMName "MyDebugVM" -VHDXPath ".\my.vhdx" -ISOPath ".\config.iso"

    Starts a VM named "MyDebugVM" with the specified VHDX and ISO, then waits for SSH.

.EXAMPLE
    PS C:\> .\Start-DebugVM.ps1 -CheckOnly

    Performs a check-only run to see what would happen without making changes.

.NOTES
    - Requires Hyper-V module and administrative privileges.
    - Assumes the VM will obtain an IP via DHCP on the "Default Switch".
    - SSH check uses TCP connection test on port 22.
    - Network neighbor discovery relies on ARP table entries with MAC prefix 00-15-5d (Hyper-V default).
#>

# cSpell: words openstack vhdx dvddrive
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VMName = "debug",
    [string]$VHDXPath = ".\alpine-openstack.vhdx",
    [string]$ISOPath = ".\seed.iso",
    [switch]$CheckOnly
)

if (-not $CheckOnly) {
    Write-Host "Starting debug VM '$VMName' with VHDX '$VHDXPath' and ISO '$ISOPath'"
    Write-Host "Resizing VHD to 20GB..."
    Resize-VHD -Path $VHDXPath -SizeBytes 20GB
    Write-Host "Creating and starting VM..."
    $null = New-VM -Name $VMName -MemoryStartupBytes 2GB -Path . -BootDevice VHD -VHDPath $VHDXPath -SwitchName "Default Switch" -Generation 1
    # Increase the number of processors to 2 for better performance
    Set-VMProcessor -VMName $VMName -Count 2
    # Set max memory to 12GB
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -MaximumBytes 12GB
    Set-VMDvdDrive -VMName $VMName -Path $ISOPath
    Start-VM $VMName
} else {
    Write-Host "Check-only mode: VM '$VMName' would be started with VHDX '$VHDXPath' and ISO '$ISOPath'"
}

# Wait for VM to be accessible via SSH
Write-Host "Waiting for VM to become accessible via SSH..."
$sshAvailable = $false
$targetIP = $null

do {
    Write-Host "  Checking for VM IP address and SSH availability..."
    Start-Sleep -Seconds 2

    $neighbors = Get-NetNeighbor -State Permanent -LinkLayerAddress 00-15-5d-* -ErrorAction SilentlyContinue

    foreach ($neighbor in $neighbors) {
        $ip = $neighbor.IPAddress
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect($ip, 22, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(1000, $false)

            if ($wait) {
                $tcpClient.EndConnect($connect)
                $sshAvailable = $true
                $targetIP = $ip
                break
            }
            $tcpClient.Close()
        } catch {
            # SSH not ready yet on this IP
        } finally {
            try { $tcpClient.Close() } catch {
                # Ignore errors on close
            }
            $tcpClient.Dispose()
        }
    }
} while (-not $sshAvailable)

Write-Host "Connect with: ssh alpine@$targetIP"
