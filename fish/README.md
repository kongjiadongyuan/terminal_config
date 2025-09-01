# Install

```fish
function tssh
    # ---------- helpers ----------
    function _has; command -sq $argv[1]; end

    # TUI input for session names
    function _input_session_name
        set -l prompt $argv[1]
        set -l header $argv[2]
        set -l default_name $argv[3]

        if _has fzf
            set -l result
            if test -n "$default_name"
                set result (echo "$default_name" | fzf \
                                            --height=100% \
                                            --margin=10% \
                                            --border=rounded \
                                            --layout=reverse \
                                            --info=hidden \
                                            --prompt="$prompt" \
                                            --header="$header" \
                                            --print-query \
                                            --expect=enter)
            else
                set result (echo "" | fzf \
                                            --height=100% \
                                            --margin=10% \
                                            --border=rounded \
                                            --layout=reverse \
                                            --info=hidden \
                                            --prompt="$prompt" \
                                            --header="$header" \
                                            --print-query \
                                            --expect=enter)
            end

            if test -z "$result"
                return 1
            end

            # fzf --print-query --expect returns: query\nkey\nselected_item
            set -l lines (string split \n -- $result)
            set -l query (string trim -- $lines[1])

            # Return the query (what user typed)
            echo "$query"
        else
            if test -n "$default_name"
                read -P "$prompt [default: $default_name]: "
            else
                read -P "$prompt: "
            end
        end
    end

    # Full-screen centered chooser (fzf). args: prompt header [items...]
    # Each item is expected to be "DISPLAY<TAB>PAYLOAD"
    function _choose_fullscreen
        set -l prompt $argv[1]
        set -l header $argv[2]
        set -l items  $argv[3..-1]
        if not _has fzf
            for i in (seq (count $items))
                # show only DISPLAY (left of TAB)
                set -l disp (string split \t -- $items[$i])[1]
                echo "$i) $disp"
            end
            read -P "Enter number: " idx
            if test -n "$idx"; and string match -qr '^[0-9]+$' -- "$idx"
                if test "$idx" -gt 0; and test "$idx" -le (count $items)
                    echo $items[$idx]
                    return 0
                end
            end
            return 1
        end
        printf "%s\n" $items | fzf \
                        --height=100% \
                        --margin=10% \
                        --border=rounded \
                        --layout=reverse \
                        --info=hidden \
                        --ansi \
                        --prompt="$prompt" \
                        --header="$header" \
                        --cycle \
                        --delimiter='\t' \
                        --with-nth=1
    end


    # ---------- args ----------
    set -l verbose false
    set -l args_parsed

    # Parse arguments
    for arg in $argv
        switch $arg
            case '-v' '--verbose'
                set verbose true
            case '*'
                set -a args_parsed $arg
        end
    end

    if test (count $args_parsed) -eq 0
        echo "Usage: tssh [-v] <host> [args...]"
        return 2
    end
    set -l host  $args_parsed[1]
    set -l rest  $args_parsed[2..-1]

    # Always enable TUI for tssh

    # ---------- probe remote tmux ----------
    set -l SEP "__TMUXSEP__"
    set -l list_cmd "command -v tmux >/dev/null 2>&1 || { echo __NO_TMUX__; exit 3; }; tmux list-sessions -F '#{session_name}$SEP#{session_windows}$SEP#{session_attached}' 2>/dev/null || true"
    set -l raw (command ssh -o BatchMode=no -o RequestTTY=no $host "$list_cmd")
    set -l rc $status

    if test $rc -ne 0
        echo "SSH probe failed. Connecting normally…"
        command ssh $argv
        return $status
    end
    if string match -q "__NO_TMUX__*" -- $raw
        echo "Remote 'tmux' not found. Connecting normally…"
        command ssh $argv
        return $status
    end

    # ---------- build items (DISPLAY \t PAYLOAD) ----------
    set -l lines (string split \n -- $raw | string trim)
    set -l items
    set -l TAG_SESSION (printf '\e[1;36m[Session]\e[0m')  # bold cyan
    set -l TAG_ACTION  (printf '\e[1;35m[Action]\e[0m')   # bold magenta

    # First pass: find and add tssh_default if it exists
    set -l tssh_default_found false
    for line in $lines
        if test -z "$line"
            continue
        end
        set -l cols (string split $SEP -- $line)
        set -l name $cols[1]
        if test "$name" = "tssh_default"
            set -l wins $cols[2]
            set -l disp "$TAG_SESSION "(printf '%-20s' $name)"  ($wins windows)"
            set -l payload "S|$name"
            set -a items "$disp"(printf '\t')"$payload"
            set tssh_default_found true
            break
        end
    end

    # Second pass: add all other sessions
    for line in $lines
        if test -z "$line"
            continue
        end
        set -l cols (string split $SEP -- $line)
        set -l name $cols[1]
        # Skip tssh_default since we already added it
        if test "$name" = "tssh_default"
            continue
        end
        set -l wins $cols[2]
        set -l disp "$TAG_SESSION "(printf '%-20s' $name)"  ($wins windows)"
        set -l payload "S|$name"
        set -a items "$disp"(printf '\t')"$payload"
    end

    # actions
    set -l disp_create "$TAG_ACTION   Create new tmux session (CC)"
    set -l disp_plain  "$TAG_ACTION   Connect without tmux"
    set -a items "$disp_create"(printf '\t')"A|create"
    set -a items "$disp_plain"(printf '\t')"A|plain"

    # ---------- TUI ----------
    set -l choice (_choose_fullscreen "Select ▸ " "Host: $host  • Use ↑/↓ and Enter" $items)
    if test -z "$choice"
        echo "Canceled."
        return 130
    end

    # parse payload
    if test "$verbose" = true
        echo "DEBUG: choice = '$choice'"
    end
    set -l parts (string split (printf '\t') -- $choice)  # actual tab character
    if test "$verbose" = true
        echo "DEBUG: parts count = "(count $parts)
        for i in (seq (count $parts))
            echo "DEBUG: parts[$i] = '$parts[$i]'"
        end
    end
    set -l payload
    if test (count $parts) -ge 2
        set payload $parts[2]
    end
    if test "$verbose" = true
        echo "DEBUG: payload = '$payload'"
    end

    if test -z "$payload"
        echo "Unknown selection. Connecting normally…"
        command ssh $host $rest
        return $status
    end

    switch (string sub -s 1 -l 1 -- $payload)
        case 'A'
            if test "$payload" = "A|plain"
                echo "Connecting without tmux…"
                command ssh $host $rest
                return $status
            else if test "$payload" = "A|create"
                # Check if tssh_default already exists
                set -l default_name "tssh_default"
                set -l tssh_default_exists false
                for line in $lines
                    if test -z "$line"
                        continue
                    end
                    set -l cols (string split $SEP -- $line)
                    set -l name $cols[1]
                    if test "$name" = "$default_name"
                        set tssh_default_exists true
                        break
                    end
                end

                set -l session  # Declare outside the loop
                while true
                    if test "$tssh_default_exists" = "true"
                        set session (_input_session_name "Enter session name ▸ " "Host: $host  • Session name is required" "")
                    else
                        set session (_input_session_name "Enter session name ▸ " "Host: $host  • Press Enter for default: $default_name" "$default_name")
                    end


                    # Handle empty session name
                    if test -z "$session" -o "$session" = ""
                        if test "$tssh_default_exists" = "false"
                            # Use default name if tssh_default doesn't exist
                                                        set session $default_name
                                                        break
                                                else
                                                        # Show error menu in TUI if tssh_default exists
                                                        set -l error_items
                                                        set -l TAG_ERROR (printf '\e[1;31m[Option]\e[0m')  # bold red
                                                        set -a error_items "$TAG_ERROR   Try againRETRY"
                                                        set -a error_items "$TAG_ERROR   ExitEXIT"

                                                        set -l error_choice (_choose_fullscreen "Session name cannot be empty ▸ " "Host: $host  • What would you like to do?" $error_items)
                                                        if test -z "$error_choice"
                                                                echo "Canceled."
                                                                return 130
                                                        end

                                                        set -l error_payload (string split "" -- $error_choice)[2]
                                                        switch "$error_payload"
                                                                case "RETRY"
                                                                        continue
                                                                case "EXIT"
                                                                        echo "Canceled."
                                                                        return 130
                                                                case "*"
                                                                        echo "Canceled."
                                                                        return 130
                                                        end
                                                end
                                        else
                                                break
                                        end
                                end

                                set -l remote_cmd "tmux -CC new-session -s \"$session\""
                                echo "Creating and connecting (tmux -CC) to '$session'…"
                                command ssh -t $host $remote_cmd
                                return $status
                        end

                case 'S'
                        set -l name (string split '|' -- $payload)[2]
                        echo "Attaching with tmux -CC to '$name'…"
                        # Or attach-or-create:
                        # command ssh -t $host "tmux -CC new-session -As \"$name\""
                        command ssh -t $host "tmux -CC attach -t \"$name\""
                        return $status
        end

        # Fallback
        echo "Unknown selection. Connecting normally…"
        command ssh $host $rest
end
funcsave tssh
```
