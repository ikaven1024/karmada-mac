#!/usr/bin/env bash

function get_repo_name() {
    name=$(basename "$1")
    echo "${name%%.*}"
}
