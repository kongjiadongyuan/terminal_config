#!/bin/bash
dir="/tmp/zellij/bootstrap"
mkdir -p "$dir"

case $(uname -m) in
    "x86_64"|"aarch64")
        arch=$(uname -m)
    ;;
    "arm64")
        arch="aarch64"
    ;;
    *)
        echo "Unsupported cpu arch: $(uname -m)"
        exit 2
    ;;
esac

case $(uname -s) in
    "Linux")
        sys="unknown-linux-musl"
    ;;
    "Darwin")
        sys="apple-darwin"
    ;;
    *)
        echo "Unsupported system: $(uname -s)"
        exit 2
    ;;
esac

url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-$arch-$sys.tar.gz"
curl --location "$url" --progress-bar | tar -C "$dir" -xz
if [[ $? -ne 0 ]]
then
    echo
    echo "Extracting binary failed, cannot launch zellij :("
    echo "One probable cause is that a new release just happened and the binary is currently building."
    echo "Maybe try again later? :)"
    exit 1
fi
mkdir -p "$HOME/.local/bin"
cp "$dir/zellij" "$HOME/.local/bin"


if ! echo "$PATH" | grep -q "$HOME/.local/bin" ; then
    RED='\033[0;31m'
    NO_COLOR='\033[0m'
    
    echo -e "${RED}WARNING: $HOME/.local/bin is not in your PATH.${NO_COLOR}"
    echo "To use zellij directly from the command-line, you should add it to your PATH."

    DEFAULT_SHELL=$(echo $SHELL)

    if [[ $DEFAULT_SHELL == */bash ]]; then
        echo "For Bash, add the following line to your ~/.bashrc or ~/.bash_profile:"
        echo -e "${RED}export PATH=\"$HOME/.local/bin:\$PATH\"${NO_COLOR}"
    elif [[ $DEFAULT_SHELL == */zsh ]]; then
        echo "For Zsh, add the following line to your ~/.zshrc:"
        echo -e "${RED}export PATH=\"$HOME/.local/bin:\$PATH\"${NO_COLOR}"
    elif [[ $DEFAULT_SHELL == */fish ]]; then
        echo "For Fish, run the following command or add it to your ~/.config/fish/config.fish:"
        echo -e "${RED}set -x PATH \$HOME/.local/bin \$PATH${NO_COLOR}"
    else
        echo "If you are using another shell, add $HOME/.local/bin to your PATH in the appropriate configuration file."
    fi
fi

mkdir -p "$HOME/.config/zellij"
curl -H "Cache-Control: no-cache" --location "https://raw.githubusercontent.com/kongjiadongyuan/terminal_config/main/zellij/config.kdl" --progress-bar > "$HOME/.config/zellij/config.kdl"
if [[ $? -ne 0 ]]
then
    echo
    echo "Downloading config.kdl failed, cannot launch zellij :("
    echo "Maybe try again later? :)"
    exit 1
fi

exit