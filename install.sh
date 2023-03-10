abort() {
    printf "%s\n" "$@" >&2
    exit 1
}
if [ -z "${BASH_VERSION:-}" ]
then
    abort "Bash is required to run this script."
fi

if [[ -t 1 ]]
then
    escape() { printf "\033[%sm" "$1"; }
else
    escape() { :; }
fi

stable_download_url="https://github.com/vibovenkat123/review-gpt/releases/download/stable"
declare -a binaries=("rgpt-linux-mips" "rgpt-linux-mips64" "rgpt-linux-mips64le" "rgpt-linux-mipsle" "rgpt-linux-ppc64" "rgpt-linux-ppc64le" "rgpt-linux-386" "rgpt-linux-amd64" "rgpt-linux-arm" "rgpt-linux-arm64" "rgpt-macos-arm64" "rgpt-macos-amd64")
mkcolor() { escape "1;$1"; }
mksecondarycolor() { escape "0;$1"; }
underline="$(escape "4;39")"
blue="$(mkcolor 34)"
red="$(mkcolor 31)"
orange="$(mksecondarycolor 33)"
green="$(mkcolor 32)"
yellow=$(mkcolor 33)
bold="$(mkcolor 39)"
reset="$(escape 0)"
cyan="$(mkcolor 36)"
shell_join() {
    local arg
    printf "%s" "$1"
    shift
    for arg in "$@"
    do
        printf " "
        printf "%s" "${arg// /\ }"
    done
}

print_same_line() {
    printf "%s" "${1/"$'\n'"/}"
}

arrow() {
    printf "${blue}==>${bold} %s${reset}\n" "$(shell_join "$@")"
}
good() {
   printf "${green}$1${reset}" 
}
warn() {
    printf "${yellow}Warning${reset}: %s\n" "$(print_same_line "$1")"
}
error() {
    printf "${red}ERROR${reset}: %s\n" "$(print_same_line "$1")"
}
info() {
    printf "${blue}Info${reset}: %s\n" "$(print_same_line "$1")"
}
action_required() {
    printf "${orange}Action Required${reset}: %s\n" "$(print_same_line "$1")"
}
print_steps() {
    printf "${bold}These are the steps the installation will do:${reset}:\n"
    declare -a steps=("1. Set up the environment variables" "2. Download the binaries" "3. Add the binaries to your path")
    for step in "${steps[@]}"
    do
        arrow $step
    done
    echo 
}
download_binaries() {
    echo 
    info "Select the binary for your correct machine. rgpt-x-y (x = os, y = architecture)"
    echo
    select binary in "${binaries[@]}"
    do
        if [[ -z "$binary" ]]
        then
            error "$REPLY is not a valid choice"
            echo 
            exit 1
        fi
        binary_input="$(( $REPLY - 1 ))"
        break
    done
    echo 
    binary_name="${binaries[$binary_input]}"
    info "The following steps requires sudo/root permissions. It will copy the file to your bin."
    wait_for_quit
    arrow "Going to bin directory"
    cd /usr/local/bin
    arrow "Downloading binaries"
    sudo curl -LJO $stable_download_url/$binary_name
    arrow "Moving the binary to the correct name"
    sudo mv $binary_name rgpt
    arrow "Giving the file executing permissions"
    sudo chmod +x /usr/local/bin/rgpt
    arrow "Going back to previous directory"
    arrow "$(cd -)"
    arrow "$( good "Successfully copied binary" )"
}
wait_for_quit() {
    echo -n "$(action_required "Press ${bold}RETURN${reset}/${bold}ENTER${reset} to continue with the installation or any other key to quit:")"
    while read -r -n 1 -s answer
    do
        if [ -z "$answer" ]
        then 
            printf "\n\n"
            break
        else
            abort
        fi
    done
}
greet() {
    printf "${cyan}Welcome to the review-gpt install/update script\n${reset}"
}
success_end() {
    echo
    echo
    good "You have successfully installed/updated review-gpt!"
    echo
    good "Whenever you want to update, run the same script."
    echo
    echo
}
ask_for_env() {
    read -p "Enter API Key for openai:" key
    echo 
    if ! [[ $key == sk-* ]]
    then
        error "The openai key you entered is not in the right format"
        exit 1
    fi
    arrow "Copying API Key to ~/.rgpt.env..."
    file_content="OPENAI_KEY=\"${key}\""
    echo $file_content > ~/.rgpt.env
    arrow $(good "Copied!!")
}
greet 

echo

wait_for_quit

print_steps

wait_for_quit

ask_for_env

download_binaries

success_end

exit 0
