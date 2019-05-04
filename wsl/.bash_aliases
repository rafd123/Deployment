WIN_HOMEPATH=$(/mnt/c/Windows/System32/cmd.exe /C echo %HOMEPATH% 2> /dev/null | tr -d '\r\n' | tr '\\' '/')
WIN_USER_PROFILE="/mnt/c/$WIN_HOMEPATH"

alias ls='ls -l --color=auto'
alias popd="popd &> /dev/null"
alias mc='mc -x'
alias deployment='pushd ~/.deployment &> /dev/null'
alias desk="pushd ~/desktop &> /dev/null"
alias docs="pushd ~/documents &> /dev/null"
