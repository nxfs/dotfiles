# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export AUTO_TITLE_SCREENS="NO"

set-title() {
    echo -e "\e]0;$*\007"
}

ssh() {
    set-title $*;
    /usr/bin/ssh -2 $*;
    set-title $HOST;
}

# checks the syntax of all modified ruby files
alias chkrb="git diff --name-only | grep "\.rb" | xargs -L1 ruby -c"

# vim bindings but keep ctrl r in insert mode
bindkey -v
bindkey '^r' history-incremental-search-backward

# remove auto rotation of screen
gsettings set org.gnome.settings-daemon.plugins.orientation active false

export EDITOR='nvim'
export VISUAL='nvim'

# make sure we have an ssh agent
if [ -z "$SSH_AGENT_PID" ]
then
	echo "SSH agent PID is not defined"

	# we could just start a new agent but we try to be more clever and identify any ssh agent launched by a previous shell

	AGENT_SOCKET=$HOME/.ssh/.ssh-agent-socket
	AGENT_INFO=$HOME/.ssh/.ssh-agent-info
	SCSSH_AGENT=/usr/bin

	if [[ -s "$AGENT_INFO" ]]
	then
		source $AGENT_INFO
	fi

	other=0
	if [[ -z "$SSH_AGENT_PID" ]]
	then
		running=0
	else
		running=0
		for u in `pgrep ssh-agent`
		do
			if [[ "$running" != "1" ]]
			then
				if [[ "$SSH_AGENT_PID" != "$u" ]]
				then
					running=2
					other=$u
				else
					running=1
					echo "Agent $u Already Running"
				fi
			fi
		done
	fi

	if [[ "$running" != "1" ]]
	then
		echo "Re-starting Agent"
		killall -15 ssh-agent
		echo "rm $AGENT_SOCKET"
		eval `rm $AGENT_SOCKET`
		echo "$SCSSH_AGENT/ssh-agent -s -a $AGENT_SOCKET"
		eval `$SCSSH_AGENT/ssh-agent -s -a $AGENT_SOCKET`
		echo "export SSH_AGENT_PID=$SSH_AGENT_PID" > $AGENT_INFO
		echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >> $AGENT_INFO
		ssh-add
	elif [[ "$other" != "0" ]]
	then
		if ps -p $other|grep $other|grep defunct >/dev/null
		then
			echo "DEFUNCT process $other is still running"
		else
			echo "WARNING!! non defunct process $other is still running"
		fi
	fi
fi
