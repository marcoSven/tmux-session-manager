#!/bin/bash
                                   
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

tmux ls &>/dev/null
TMUX_STATUS=$?

BORDER_LABEL=" Tmux Session Manager "
HEADER="alt-a: All | alt-s: Sessions | alt-z: Zoxide | alt-d: Directory"

PROMPT="All> "

tempdir=$(mktemp -d "${SCRIPTPATH}/temp.XXXXXXXXX")

trap 'rm -rf "$tempdir"; exit' ERR EXIT TERM

if [ $TMUX_STATUS -eq 0 ];then

	ALL_BIND="alt-a:change-prompt($PROMPT)+execute-silent(echo a > $tempdir/filter)+reload($SCRIPTPATH/tmux && $SCRIPTPATH/zoxide $tempdir)"

	SESSION_BIND="alt-s:change-prompt(Sessions> )+execute-silent(echo s > $tempdir/filter)+reload($SCRIPTPATH/tmux)"

	DETACH_BIND="ctrl-d:execute-silent(tmux detach -s {})+reload($SCRIPTPATH/tmux && $SCRIPTPATH/zoxide $tempdir)"

	KILL_BIND="ctrl-x:execute-silent(tmux kill-session -t {})+reload($SCRIPTPATH/tmux && $SCRIPTPATH/zoxide $tempdir)"

else 
    ALL_BIND="alt-a:change-prompt($PROMPT)+reload($SCRIPTPATH/zoxide $tempdir)"
	SESSION_BIND="alt-s:change-prompt(Sessions> )+reload()"
	DETACH_BIND="ctrl-d:execute-silent()"
	KILL_BIND="ctrl-x:execute-silent()"
fi

ZOXIDE_BIND="alt-z:change-prompt(Zoxide> )+reload($SCRIPTPATH/zoxide)"
DIR_BIND="alt-d:change-prompt(Directory> )+reload(cd $HOME && echo $HOME; fd --type d --hidden --absolute-path --color never --exclude .git --exclude node_modules)"

Z_BIND="alt-Z:execute-silent(touch $tempdir/z)+become(echo '{}')"

[ "$TMUX" = "" ] && FZF=fzf || FZF=fzf-tmux

[ "$TMUX" = "" ] || float="-p 70%" 

RESULT=$(
	($SCRIPTPATH/tmux && $SCRIPTPATH/zoxide) | $FZF \
	    $float \
		--reverse \
		--header "$HEADER" \
		--prompt "$PROMPT" \
		--border-label "$BORDER_LABEL" \
		--bind "$ALL_BIND" --bind "$DIR_BIND"  --bind "$ZOXIDE_BIND" \
		--bind "$SESSION_BIND" --bind "$DETACH_BIND" --bind "$KILL_BIND" --bind "$Z_BIND" \
		--preview="$SCRIPTPATH/preview '{}'" \
		--preview-window=down,30%,sharp
)

[ "$RESULT" = "" ] && exit 0

[ -f $tempdir/z ] && echo "$RESULT" && exit 0

# get real home path back
echo "$HOME" | grep -E "^[a-zA-Z0-9\-_/.@]+$" &>/dev/null # chars safe to use in sed
[ $? -eq 0 ] && RESULT=$(echo "$RESULT" | sed -e "s|^~/|$HOME/|") 

FOLDER=$(basename "$RESULT")
SESSION_NAME=$(echo "$FOLDER" | tr ' ' '_' | tr '.' '_' | tr ':' '_')

# add to zoxide database
[ -d "$RESULT" ] && zoxide add "$RESULT" &>/dev/null 

[ $TMUX_STATUS -eq 0 ] && SESSION=$($SCRIPTPATH/tmux | grep "^$SESSION_NAME$") || SESSION=""


if [ "$TMUX" = "" ]; then
	[ "$SESSION" = "" ] && tmux new-session -s "$SESSION_NAME" -c "$RESULT" || tmux attach -t "$SESSION"

	exit 0                      
fi  

if [ "$SESSION" = "" ]; then                        
	tmux new-session -d -s "$SESSION_NAME" -c "$RESULT" 
	tmux switch-client -t "$SESSION_NAME"  

	exit 0             												
fi

[ "$(tmux display-message -p '#S')" = "$SESSION" ] && echo "$(zoxide query "$SESSION")" || tmux switch-client -t "$SESSION"
