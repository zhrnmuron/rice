#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export LD_PRELOAD="/usr/lib/libgio-2.0.so /usr/lib/libgmodule-2.0.so /usr/lib/libglib-2.0.so"
