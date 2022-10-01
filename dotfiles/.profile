# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

export PS1="\[\033[0;32m\]\u\[\033[0m\]@\[\033[0;31m\]\h\[\033[0m\]: \[\033[0;36m\]\w\[\033[0m\] $ "
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export HISTCONTROL=ignorespace
export HISTIGNORE="&:ls:ls -l:ls -la:clear:exit"
export EDITOR='/bin/vim'