### !powershell

# POWERSHELL_COMMON

#AnsibleRequires -CSharpUtil Ansible.Basic


Function SetIp{
  Param (
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][int]$subNet,
    [Parameter(Mandatory=$true)][int]$interfaceIndex,
    [string]$gateway
  )

  $interface = Get-NetAdapter -ifIndex $interfaceIndex

  Try{
    Try{
      Remove-NetRoute -InterfaceIndex $interfaceIndex  -Confirm:$false
    }Catch{}
    Remove-NetIPAddress -InterfaceIndex $interfaceIndex -Confirm:$false
    if ( $gateway -eq "0.0.0.0" ){
      New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $ip -PrefixLength $subNet -Confirm:$false
    }else{
      New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $ip -PrefixLength $subNet -DefaultGateway $gateway -Confirm:$false
    }
  }Catch{
    Write-Host "$_" 2>&1 >> 'C:\TEMP\out.txt'
    Throw $_
  }

  $dateTime=[datetime]::Now.ToString('HH:mm:ss')
  Write-Host "SetIp $dateTime ip:$ip subNet:$subNet interfaceIndex:" + (Get-NetAdapter -ifIndex $interfaceIndex).ifAlias + " gateway:$gateway" 2>&1 >> 'C:\TEMP\out.txt'
}

function RaiseError {
  Param (
    [string]$msg="Unknown error"
  )

  $module.Result.msg = $msg
  $module.Result.failed = $true
  $module.Result.error = $true
  $module.ExitJson()
}

$spec = @{
    options = @{
        ip = @{ type = "str"; required = $true }
        interface = @{ type = "str"; default = "Ethernet0" }
        subNet = @{ type = "int"; default = 24; choices = 0,1,2,3,4,5,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32 }
        gateway = @{ type = "str"; default = "0.0.0.0" }
        currentInterface = @{ type = "bool"; default = $false }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$ip = $module.Params.ip
$interfaceName = $module.Params.interface
$subNet = $module.Params.subNet
$gateway = $module.Params.gateway
$cuI = $module.Params.currentInterface
$module.Result.changed = $false

# RaiseError "$gateway"

$ipv4Regex='^(((25[012345])|(2[01234][0-9])|[01]?[0-9]?[0-9])\.){3}((25[012345])|(2[01234][0-9])|[01]?[0-9]?[0-9])$'

if ( -not ($ip -match $ipv4Regex)) {
  RaiseError "Error parameter ip:$ip is not an ipv4"
}

if ( ! ($gateway -eq "0.0.0.0" -or $gateway -match $ipv4Regex)) {
  RaiseError "Error parameter gateway:$gateway is not an ipv4"
}

$adapter=(Get-NetAdapter | Where-Object { $_.Name -eq $interfaceName })

if ( $adapter -eq $null) {
  RaiseError "No such interface $interfaceName"
}

$interface = ( $adapter | Get-NetIPInterface -AddressFamily "IPv4" )
# $dhcp=($interface.Dhcp -eq "Enabled")

# if($dhcp){
#   #get ip conf to rollback
# }

if($cuI){

  $dateTime=[datetime]::Now
  $T = New-JobTrigger -Once -At $dateTime.AddSeconds(2)
  $O = New-ScheduledJobOption -StartIfOnBattery -RunElevated -WakeToRun
  $dateTimeString=$dateTime.ToString('yyyyMMdd HH mm ss')
  Register-ScheduledJob -Name ("Setting up IP $ip of card " + $interface.ifAlias+" at $dateTimeString") -ScheduledJobOption $O -Trigger $T -ScriptBlock ${Function:SetIp} -ArgumentList $ip,$subNet,$adapter.ifIndex,$gateway
}else{
  Try{
    SetIp $ip $subNet $adapter.ifIndex $gateway
  }Catch{
    RaiseError $_
  }
}

$module.Result.changed = $true

$module.ExitJson()