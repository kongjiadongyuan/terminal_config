function ssh {
    param([string] $target_host)
    $ssh_config_path = "$home\.ssh\ssh_config.json"
    $builtin_ssh = (Get-Command ssh -CommandType Application -All)[0].Source
    # Write-Host $builtin_ssh
    if (Test-Path $ssh_config_path) {
        # Write-Host  "Using ssh_config.json"
        $ssh_config = Get-Content -Raw -Path $ssh_config_path | ConvertFrom-Json
        if ($ssh_config.PSObject.Properties.Name -contains $target_host) {
            # Write-Host "Connecting to $target_host"
            $command_to_execute = $ssh_config.$target_host
            # Write-Host "Executing $command_to_execute"
            $exp = "& `"$builtin_ssh`" -t $target_host `"$command_to_execute`""
            # Write-Host $exp
            Invoke-Expression $exp
            return
        }
    }
    Invoke-Expression "& `"$builtin_ssh`" -t $target_host $args"
}

function sssh {
    $builtin_ssh = (Get-Command ssh -CommandType Application -All)[0].Source
    Invoke-Expression "& `"$builtin_ssh`" $args"
}