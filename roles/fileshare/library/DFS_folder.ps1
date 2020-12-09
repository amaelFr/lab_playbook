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
        path = @{ type = "str"; required = $true }
        smb_dst = @{ type = "str"; }
        state = @{ type = "bool"; default = $true }
        online= @{ type = "bool"; default = $true }
        
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$path = $module.Params.path
$smb_dst = $module.Params.smb_dst
$state = $module.Params.state

Try {
    
    If ($smb_dst){
        $DFSnFolder = Get-DfsnFolderTarget -Path $path -TargetPath $smb_dst
    }Else{
        $DFSnFolder = Get-DfsnFolder -Path $path
    }

    If ($state -eq "absent") {
        If ($DFSnFolder) {
            If ($smb_dst){
                Remove-DfsnFolderTarget -Path $path -TargetPath $smb_dst
            }Else{
                Remove-DfsnFolder -Path $path
            }
            $module.Result.changed = $true;
        }
    } Else {
        If ($smb_dst){
            Test-Path "smb::$smb_dst"
        }Else{
            
        }
    }

    If ($state -eq "absent") {
        If ($share) {
            Remove-SmbShare -Force -Name $name
            Set-Attr $result "changed" $true;
        }
    } Else {
        $path = Get-Attr $params "path" -failifempty $true
        $description = Get-Attr $params "description" ""

        $permissionList = Get-Attr $params "list" "no" -validateSet "no","yes" -resultobj $result | ConvertTo-Bool
        $folderEnum = if ($permissionList) { "Unrestricted" } else { "AccessBased" }

        $permissionRead = Get-Attr $params "read" "" | NormalizeAccounts
        $permissionChange = Get-Attr $params "change" "" | NormalizeAccounts
        $permissionFull = Get-Attr $params "full" "" | NormalizeAccounts
        $permissionDeny = Get-Attr $params "deny" "" | NormalizeAccounts

        If (-Not (Test-Path -Path $path)) {
            Fail-Json $result "$path directory does not exist on the host"
        }

        # normalize path and remove slash at the end
        $path = (Get-Item $path).FullName -replace "\\$"

        # need to (re-)create share
        If (!$share) {
            New-SmbShare -Name $name -Path $path
            $share = Get-SmbShare $name -ErrorAction SilentlyContinue

            Set-Attr $result "changed" $true;
        }
        If ($share.Path -ne $path) {
            Remove-SmbShare -Force -Name $name

            New-SmbShare -Name $name -Path $path
            $share = Get-SmbShare $name -ErrorAction SilentlyContinue

            Set-Attr $result "changed" $true;
        }

        # updates
        If ($share.Description -ne $description) {
            Set-SmbShare -Force -Name $name -Description $description
            Set-Attr $result "changed" $true;
        }
        If ($share.FolderEnumerationMode -ne $folderEnum) {
            Set-SmbShare -Force -Name $name -FolderEnumerationMode $folderEnum
            Set-Attr $result "changed" $true;
        }

        # clean permissions that imply others
        ForEach ($user in $permissionFull) {
            $permissionChange.remove($user)
            $permissionRead.remove($user)
        }
        ForEach ($user in $permissionChange) {
            $permissionRead.remove($user)
        }

        # remove permissions
        $permissions = Get-SmbShareAccess -Name $name
        ForEach ($permission in $permissions) {
            If ($permission.AccessControlType -eq "Deny") {
                If (!$permissionDeny.Contains($permission.AccountName)) {
                    Unblock-SmbShareAccess -Force -Name $name -AccountName $permission.AccountName
                    Set-Attr $result "changed" $true;
                }
            }
            ElseIf ($permission.AccessControlType -eq "Allow") {
                If ($permission.AccessRight -eq "Full") {
                    If (!$permissionFull.Contains($permission.AccountName)) {
                        Revoke-SmbShareAccess -Force -Name $name -AccountName $permission.AccountName
                        Set-Attr $result "changed" $true;

                        Continue
                    }

                    # user got requested permissions
                    $permissionFull.remove($permission.AccountName)
                }
                ElseIf ($permission.AccessRight -eq "Change") {
                    If (!$permissionChange.Contains($permission.AccountName)) {
                        Revoke-SmbShareAccess -Force -Name $name -AccountName $permission.AccountName
                        Set-Attr $result "changed" $true;

                        Continue
                    }

                    # user got requested permissions
                    $permissionChange.remove($permission.AccountName)
                }
                ElseIf ($permission.AccessRight -eq "Read") {
                    If (!$permissionRead.Contains($permission.AccountName)) {
                        Revoke-SmbShareAccess -Force -Name $name -AccountName $permission.AccountName
                        Set-Attr $result "changed" $true;

                        Continue
                    }

                    # user got requested permissions
                    $permissionRead.Remove($permission.AccountName)
                }
            }
        }
        
        # add missing permissions
        ForEach ($user in $permissionRead) {
            Grant-SmbShareAccess -Force -Name $name -AccountName $user -AccessRight "Read"
            Set-Attr $result "changed" $true;
        }
        ForEach ($user in $permissionChange) {
            Grant-SmbShareAccess -Force -Name $name -AccountName $user -AccessRight "Change"
            Set-Attr $result "changed" $true;
        }
        ForEach ($user in $permissionFull) {
            Grant-SmbShareAccess -Force -Name $name -AccountName $user -AccessRight "Full"
            Set-Attr $result "changed" $true;
        }
        ForEach ($user in $permissionDeny) {
            Block-SmbShareAccess -Force -Name $name -AccountName $user
            Set-Attr $result "changed" $true;
        }
    }
}
Catch {
    RaiseError "an error occured when attempting to create share $name"
}