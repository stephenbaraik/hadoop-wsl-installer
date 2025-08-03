# PowerShell script to set up port forwarding for Hadoop Web UIs in WSL2
# Run this as Administrator in Windows PowerShell

param(
    [switch]$Add,
    [switch]$Remove,
    [switch]$List,
    [string]$WSLDistro = "Ubuntu"
)

$ErrorActionPreference = "Stop"

# Hadoop ports
$ports = @(9870, 8088, 9864, 19888, 8042)
$portNames = @{
    9870 = "NameNode"
    8088 = "ResourceManager" 
    9864 = "DataNode"
    19888 = "JobHistory"
    8042 = "NodeManager"
}

function Get-WSLIPAddress {
    param([string]$distro)
    
    try {
        $wslIP = wsl -d $distro hostname -I 2>$null
        if ($wslIP) {
            return $wslIP.Trim()
        }
    }
    catch {
        Write-Warning "Could not get WSL IP for distro: $distro"
    }
    
    # Fallback: try to get IP from WSL network adapter
    try {
        $adapter = Get-NetAdapter -Name "*WSL*" | Select-Object -First 1
        if ($adapter) {
            $ip = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 | Select-Object -First 1
            return $ip.IPAddress
        }
    }
    catch {
        Write-Warning "Could not determine WSL IP address"
    }
    
    return $null
}

function Add-PortForwarding {
    $wslIP = Get-WSLIPAddress -distro $WSLDistro
    if (-not $wslIP) {
        Write-Error "Could not determine WSL IP address. Make sure WSL is running."
        return
    }
    
    Write-Host "WSL IP Address: $wslIP" -ForegroundColor Green
    Write-Host "Setting up port forwarding for Hadoop services..." -ForegroundColor Yellow
    
    foreach ($port in $ports) {
        $serviceName = $portNames[$port]
        try {
            netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIP
            Write-Host "✓ Port $port forwarded for $serviceName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to forward port $port for $serviceName"
        }
    }
    
    Write-Host "`nHadoop Web UIs should now be accessible at:" -ForegroundColor Cyan
    Write-Host "  NameNode:        http://localhost:9870" -ForegroundColor White
    Write-Host "  ResourceManager: http://localhost:8088" -ForegroundColor White
    Write-Host "  DataNode:        http://localhost:9864" -ForegroundColor White
    Write-Host "  JobHistory:      http://localhost:19888" -ForegroundColor White
    Write-Host "  NodeManager:     http://localhost:8042" -ForegroundColor White
}

function Remove-PortForwarding {
    Write-Host "Removing port forwarding rules..." -ForegroundColor Yellow
    
    foreach ($port in $ports) {
        $serviceName = $portNames[$port]
        try {
            netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0
            Write-Host "✓ Port forwarding removed for port $port ($serviceName)" -ForegroundColor Green
        }
        catch {
            Write-Warning "No forwarding rule found for port $port"
        }
    }
}

function List-PortForwarding {
    Write-Host "Current port forwarding rules:" -ForegroundColor Yellow
    netsh interface portproxy show all
}

function Show-Help {
    Write-Host "Hadoop WSL2 Port Forwarding Script" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  .\port-forward.ps1 -Add       # Add port forwarding rules" -ForegroundColor White
    Write-Host "  .\port-forward.ps1 -Remove    # Remove port forwarding rules" -ForegroundColor White
    Write-Host "  .\port-forward.ps1 -List      # List current rules" -ForegroundColor White
    Write-Host ""
    Write-Host "Run as Administrator in Windows PowerShell" -ForegroundColor Yellow
}

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Right-click PowerShell and select 'Run as Administrator'"
    exit 1
}

# Execute based on parameters
if ($Add) {
    Add-PortForwarding
}
elseif ($Remove) {
    Remove-PortForwarding
}
elseif ($List) {
    List-PortForwarding
}
else {
    Show-Help
}
