#!/bin/bash

# strict mode
set -euo pipefail

# --

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export TASK_FILTER="${1-(endpoints?-|log-)}"

# --

function config() {
	just --unstable --dump --dump-format json
}

function task_args() {
	local task=$1
	config | jq -r ".recipes[\"${task}\"].parameters[].name"
}

function task_list() {
	config | jq -r '.recipes[] | select(.attributes | contains(["private"]) | not) | .name' | sort
}

function task_list_all() {
	config | jq -r '.recipes[].name' | sort
}

function task_list_allowed() {
	config | task_list | egrep "^${TASK_FILTER}"
}

# --

function prompt_task() {
	local task=$1
	local args=$(task_args "${task}")
	local args_str=""

	local arg

	for arg in ${args}; do
		value=$(eval just prompt ${arg} ${task} ${args_str})
		[[ -z "${value}" ]] && exit 1
		echo "< ${arg}: ${value}" >&2
		args_str="${args_str} '${value}'"
	done

	echo "${args_str}"
}

function help() {
	just --list --unsorted | egrep "${TASK_FILTER}"
}

function main() {
	while true; do
		local special_tasks="help quit"

		local task=$(
			echo -e "${special_tasks// /$'\n'}\n$(task_list_allowed)" |
				fzf --prompt "task > "
		)

		if [[ -z "${task}" ]]; then
			echo "# task not selected"
			exit 1
		fi

		echo "# ${task}" >&2

		case "${task}" in

		"help")
			help
			continue
			;;

		"quit")
			echo "Bye!" >&2
			exit 0
			;;

		*)
			args=$(prompt_task ${task})
			eval "just ${task} ${args}"
			;;

		esac
	done
}

(return 0 2>/dev/null) || main $@
