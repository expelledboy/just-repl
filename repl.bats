#!/usr/bin/env bats

all_tasks=(
	"default"
	"endpoint-create"
	"endpoint-delete"
	"endpoint-disable"
	"endpoint-enable"
	"endpoint-list"
	"endpoint-move"
	"prompt-endpoint"
	"prompt-env"
	"prompt-filter"
	"prompt-name"
	"prompt-to_env"
	"test"
)

private_tasks=(
	"default"
	"prompt-endpoint"
	"prompt-env"
	"prompt-filter"
	"prompt-name"
	"prompt-to_env"
	"test"
)

public_tasks=($(
	comm -3 \
		<(printf "%s\n" "${all_tasks[@]}" | sort) \
		<(printf "%s\n" "${private_tasks[@]}" | sort) |
		sort -n
))

function setup() {
	bats_load_library bats-support
	bats_load_library bats-assert

	source $BATS_TEST_DIRNAME/repl.sh && export -f \
		config \
		task_args \
		task_list \
		task_list_all \
		task_list_allowed
}

@test "dump just config as json" {
	run config
	assert_success
	jq '.' <<<"$output" >/dev/null
}

@test "get task args" {
	run task_args endpoint-create
	assert_success
	assert_line --index 0 env
	assert_line --index 1 name
}

@test "list tasks" {
	run task_list
	assert_success

	for private_task in "${private_tasks[@]}"; do
		refute_line "$private_task"
	done

	for public_task in "${!public_tasks[@]}"; do
		assert_line --index "$public_task" "${public_tasks[$public_task]}"
	done

	assert test "${#lines[@]}" -eq "${#public_tasks[@]}"
}

@test "list all tasks" {
	run task_list_all
	assert_success

	for task in "${!all_tasks[@]}"; do
		assert_line --index "$task" "${all_tasks[$task]}"
	done

	assert test "${#lines[@]}" -eq "${#all_tasks[@]}"
}

@test "list allowed tasks" {
	export TASK_FILTER="endpoint-(enable|disable)"

	run task_list_allowed
	assert_success

	assert_line --index 0 "endpoint-disable"
	assert_line --index 1 "endpoint-enable"

	assert test "${#lines[@]}" -eq 2
}
