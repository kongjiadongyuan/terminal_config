function ssh {
    $builtin_ssh = (Get-Command ssh -CommandType Application -All)[0].Source
    if ($args.Count -eq 1) {
        $ssh_config_path = "$home\.ssh\ssh_config.json"
        if (Test-Path $ssh_config_path) {
            $target_host = $args[0]
            $ssh_config = Get-Content -Raw -Path $ssh_config_path | ConvertFrom-Json
            if ($ssh_config.PSObject.Properties.Name -contains $target_host) {
                $command_to_execute = $ssh_config.$target_host

                # For windows terminal tab name
                $host.ui.RawUI.WindowTitle = $target_host

                $exp = "& `"$builtin_ssh`" -t $target_host `"$command_to_execute`""
                Write-Host "Executing: $exp"
                Invoke-Expression $exp
                return
            }
        }
    }

    $exp = "& `"$builtin_ssh`" $args"
    Write-Host "Executing: $exp"
    Invoke-Expression $exp
}

function sssh {
    $builtin_ssh = (Get-Command ssh -CommandType Application -All)[0].Source
    Write-Host "Executing: $exp"
    Invoke-Expression "& `"$builtin_ssh`" $args"
}
