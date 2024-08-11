#!/usr/bin/env bats

# Define a logging function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >&2
}

setup() {
    export SSH_CONFIG_FILE=$(mktemp)
    log "Creating temporary SSH config file at $SSH_CONFIG_FILE"
}

teardown() {
    log "Removing temporary SSH config file at $SSH_CONFIG_FILE"
    rm -f "$SSH_CONFIG_FILE"
}

@test "normalize_ssh_file normalizes the ssh file correctly" {
    local actual_path
    local expected_path

    log "Sourcing ssh_config_remove.sh"
    source ./ssh_config_remove.sh

    log "Copying fixture to temporary SSH config file"
    cp "fixtures/normalize_actual_1" "$SSH_CONFIG_FILE"

    log "Calling normalize_ssh_file function"
    normalize_ssh_file "$SSH_CONFIG_FILE"

    log "Diffing actual normalized SSH config file with expected output"
    if ! diff -u "fixtures/normalize_expected_1" "$SSH_CONFIG_FILE"; then
        log "Diff found differences between expected and actual output"
        false
    fi
}

@test "ssh_config_remove removes the specified IdentityFile" {
    local fixtures=(
        "ssh_config_actual_1:ssh_config_expected_1"
        "ssh_config_actual_2:ssh_config_expected_2"
        "ssh_config_actual_3:ssh_config_expected_3"
        "ssh_config_actual_4:ssh_config_expected_4"
        "ssh_config_actual_5:ssh_config_expected_5"
        "ssh_config_actual_6:ssh_config_expected_6"
    )

    local KEY_NAME="id_rsa_github"
    local KEY_PATH="$HOME/.ssh/$KEY_NAME"
    local GITHUB_HOSTNAME="github.com"

    log "Sourcing ssh_config_remove.sh"
    source ./ssh_config_remove.sh

    for fixture_pair in "${fixtures[@]}"; do
        IFS=':' read -r actual_fixture expected_fixture <<< "$fixture_pair"

        if [ ! -f "fixtures/$actual_fixture" ]; then
            log "Actual fixture file does not exist: fixtures/$actual_fixture"
            exit 1
        fi

        if [ ! -f "fixtures/$expected_fixture" ]; then
            log "Expected fixture file does not exist: fixtures/$expected_fixture"
            exit 1
        fi

        log "Copying fixtures/$actual_fixture to temporary SSH config file"
        cp "fixtures/$actual_fixture" "$SSH_CONFIG_FILE"

        log "Calling ssh_config_remove for $actual_fixture"
        ssh_config_remove "$GITHUB_HOSTNAME" "$SSH_CONFIG_FILE" 

        log "Actual SSH config file: $SSH_CONFIG_FILE"
        log "Expected SSH config file: fixtures/$expected_fixture"

        log "Asserting the contents of the SSH config file after removal using diff"
        if ! diff -u "fixtures/$expected_fixture" "$SSH_CONFIG_FILE"; then
            log "Diff found differences between expected and actual output for $actual_fixture"
            false
        fi
    done
}
