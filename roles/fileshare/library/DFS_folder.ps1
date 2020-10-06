### !powershell

# POWERSHELL_COMMON

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        folder = @{ type = "str"; required = $true }
        path = @{ type = "str"; required = $true }
        smb_dst = @{ type = "str"; }
        state = @{ type = "bool"; default = $true }
        
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$folder = $module.Params.folder
$path = $module.Params.path
$smb_dst = $module.Params.smb_dst


