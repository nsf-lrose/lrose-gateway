# .bashrc

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias ofl='openstack floating ip list'
alias ofc='openstack floating ip create public'
alias osl='openstack server list'
alias onl='openstack network list'
alias ovl='openstack volume list'
alias k='kubectl'
alias kctl='kubectl'
alias h='history'
alias hist='history'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

source /home/openstack/bin/openrc.sh

function set_prompt() {
  local cluster_name="${CLUSTER:-openstack}"
  PS1='\[\e[1;32m\]❯\[\e[1;31m\] ('"$cluster_name"') \[\e[1;34m\]\w\[\e[0m\] ➜ '
}

PROMPT_COMMAND=set_prompt
