# Install

```fish
function ssh
    if test (count $argv) -eq 1
        set ssh_config_path "$HOME/.ssh/ssh_config.json"
        if test -e $ssh_config_path
            set target_host $argv[1]
            set ssh_config (cat $ssh_config_path | jq -r .)
            if echo $ssh_config | jq -e ".[\"$target_host\"]" >/dev/null
                set command_to_execute (jq -r --arg host "$target_host" '.[$host]' $ssh_config_path)
                # For terminal tab name, Fish does not have a direct equivalent to PowerShell's $host.ui.RawUI.WindowTitle
                echo "Executing: ssh -t $target_host '$command_to_execute'"
                command ssh -t $target_host "$command_to_execute"
                return
            end
        end
    end

    echo "Executing: ssh $argv"
    command ssh $argv
end

funcsave ssh

function sssh 
    command ssh $argv
end

funcsave sssh

mkdir -p $HOME/.ssh
touch $HOME/.ssh/ssh_config.json
echo "{" >> $HOME/.ssh/ssh_config.json
echo "   \"example_host\": \"example_command\"" >> $HOME/.ssh/ssh_config.json
echo "}" >> $HOME/.ssh/ssh_config.json
```

# Config ssh target

change ~/.ssh/ssh_config.json
