### !powershell

# POWERSHELL_COMMON

#AnsibleRequires -CSharpUtil Ansible.Basic


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
        # version = @{ type = "str"; required = $false; default="" }
        version = @{ type = "str"; required = $true }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$version = $module.Params.version

$major

if ($version -ne ""){
    if ( -not $version -match "^([0-9]+\.){2}[0-9]-[0-9]$"){
        RaiseError "The giving version is not valid: ^([0-9]+\.){2}[0-9]-[0-9]$"
    }

    $major = [regex]::match($version,"^([0-9]+)").Value

    curl "http://packages.treasuredata.com.s3.amazonaws.com/$major/windows/td-agent-$version-x64.msi" -o C:/TEMP/td-agent.msi
}else{
    # TODO it have to be done, add the functionnality and remove version required by defaults = ""
    RaiseError "error version = null string"
}

Try{
    msiexec.exe /i C:\TEMP\td-agent.msi /qn

    if( -not $?){
        RaiseError "Error while installing fluentd agent"
    }
}Catch{
    RaiseError "Error while installing fluentd agent, $_"
}

rm C:/TEMP/td-agent.msi

$module.Result.changed = $true

$module.ExitJson()