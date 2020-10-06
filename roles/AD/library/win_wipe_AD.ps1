### !powershell

# POWERSHELL_COMMON

#AnsibleRequires -CSharpUtil Ansible.Basic

Function UninstallAD{
  Param (
    [Parameter(Mandatory=$true)]$pass
  )

  Uninstall-ADDSDomainController -LocalAdministratorPassword $pass -DemoteOperationMasterRole -LastDomainControllerInDomain -RemoveApplicationPartition -Confirm:$false
}
# -NoRebootOnCompletion
function RaiseError {
  Param (
    [string]$msg="Unknown error"
  )

  $module.Result.msg = $msg
  $module.Result.failed = $true
  $module.ExitJson()
}

$spec = @{
    options = @{
        localAdminPassword = @{ type = "str"; required = $true }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$pass = (ConvertTo-SecureString -AsPlainText $module.Params.localAdminPassword -Force)
$module.Result.changed = $false
$module.Result.failed = $false

Try{
  Get-ADDomain

  $testUninstall=Test-ADDSDomainControllerUninstallation -LocalAdministratorPassword $pass -DemoteOperationMasterRole -LastDomainControllerInDomain -RemoveApplicationPartitions
  if ($testUninstall.Status -ne "Success" ){
    Throw $testUninstall.Message
  }

  $dateTime=[datetime]::Now
  $T = New-JobTrigger -Once -At $dateTime.AddSeconds(2)
  $O = New-ScheduledJobOption -StartIfOnBattery -RunElevated -WakeToRun
  $dateTimeString=$dateTime.ToString('yyyyMMdd HH mm ss')
  Register-ScheduledJob -Name "Uninstall domain $dateTimeString" -ScheduledJobOption $O -Trigger $T -ScriptBlock ${Function:UninstallAD} -ArgumentList $pass
  $module.Result.changed = $true
}Catch{
  if ($_ -like "Unable to find a default server with Active Directory Web Services running."){
    $module.Result.msg = "Active directory not configured"
  }elseif($_ -like "The term 'Get-ADDomain' is not recognized as the name of a cmdlet*"){
    $module.Result.msg = "Active directory not installed"
  }else{
    RaiseError $_
  }
}

$module.ExitJson()