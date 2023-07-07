set positional-arguments

export FZF_DEFAULT_OPTS := '--height 40% --layout=reverse --border'

[private]
@default:
	bash ./repl.sh

[private]
test:
	bats *.bats

# --

prompt arg *args:
	#!/bin/sh
	case {{ arg }} in
		endpoint)
			case $2 in
				endpoint-enable)  just endpoint-list disabled ;;
				endpoint-disable) just endpoint-list enabled ;;
				endpoint-move)    just endpoint-list | grep "$3" ;;
			esac | fzf --prompt="endpoint > " ;;
		from_env | env)
			ls {{ config_dir }} | fzf --prompt="{{ arg }} > " ;;
		to_env)
			ls {{ config_dir }} | grep -v $3 | fzf --prompt="env > " ;;
		name)
			read -r -p "name> " name
			echo ${name} ;;
		filter)
			echo ".*" ;;
		*)
			echo "unknown arg: {{ arg }}" >&2
			exit 1 ;;
	esac

# --

config_dir := "config"

@endpoint-list filter=".*":
	find {{ config_dir }} -type f -exec grep -q "{{ filter }}" {} \; -print

endpoint-create env name:
	echo disabled > {{ config_dir }}/{{ env }}/{{ name }}

endpoint-enable endpoint:
	@test -f {{ endpoint }}
	echo enabled > {{ endpoint }}

endpoint-disable endpoint:
	@test -f {{ endpoint }}
	echo disabled > {{ endpoint }}

endpoint-delete endpoint:
	@test -f {{ endpoint }}
	rm {{ endpoint }}

endpoint-move from_env to_env endpoint:
	#!/bin/sh
	test -f {{ endpoint }}
	to_endpoint="{{ config_dir }}/{{ to_env }}/$(basename {{ endpoint }})"
	test ! -f ${to_endpoint}
	mv {{ endpoint }} ${to_endpoint}