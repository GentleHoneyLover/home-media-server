alias clear='clear && printf "\e[3J"'
alias ll='ls -FlAhp'
alias ..='cd ..'
alias ~='cd ~'
alias dc='docker-compose -f /.../docker-compose.yml'
alias dp='docker system prune --all --volumes'
alias v='vim'
alias V='sudo vim'

alias OpenPorts='sudo netstat -lntp'
alias TransferFiles='rsync -a --progress --stats --human-readable'
alias ShowMyIP='curl ipinfo.io/ip && echo'
alias CPUTemp='sensors | grep "Core" | cut -f1-10 -d " "'
alias Download='wget -P ~/Downloads/'
alias ShowDisks='sudo lshw -class disk -short && echo && lsblk -f  && echo && df -h && echo && zpool status -v'

de() {
	docker exec -it $1 bash
}

des() {
	docker exec -it $1 sh
}