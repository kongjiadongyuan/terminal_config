function ssh
    set -l ssh_config_file ~/.config/fish/ssh_commands.txt
    set -l target_host $argv[1]

    if test (count $argv) -eq 1 -a -f $ssh_config_file
        for line in (cat $ssh_config_file)
            if string match -qr "^#" -- $line
                continue
            end
            set -l host_cmd (string split " " -- $line)
            if test $target_host = $host_cmd[1]
                command ssh -t $target_host (string join " " -- $host_cmd[2..-1])
                return
            end
        end
    else
        command ssh $argv
    end
end