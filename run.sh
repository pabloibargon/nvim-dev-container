
#!/usr/bin/env bash
set -euo pipefail

HOST_OS="linux"
DOCKER_DISPLAY_ARGS=(
    -e "DISPLAY=${DISPLAY:-:0}"
    -v "/tmp/.X11-unix:/tmp/.X11-unix"
)

if grep -qEi "(Microsoft|WSL)" /proc/version; then
    HOST_OS="wsl"
    DOCKER_DISPLAY_ARGS+=(
        # ACCESS TO WINDOWS FILES
        -v "/mnt/c:/mnt/c"
        # Allow container to read the Kernel's exe-handling rules
        -v "/proc/sys/fs/binfmt_misc:/proc/sys/fs/binfmt_misc"
        # Shared libraries for the interop bridge?
        -v "/usr/lib/wsl:/usr/lib/wsl"
        # Graphics (Keep this for clipboard support even if not using browser)
        -v "/mnt/wslg:/mnt/wslg"
        -v "/mnt/wslg/.X11-unix:/tmp/.X11-unix"
    )
else
    USER_ID=$(id -u)
    DOCKER_DISPLAY_ARGS+=(
        # DBUS: Allows talking to the host's session (Browser, File Manager)
        -v "/run/user/$USER_ID/bus:/run/user/$USER_ID/bus"
        -e "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"
	# needed to use dbus
        --security-opt apparmor=unconfined
    )
fi

# Global variable to hold the resulting combination name
combination=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#######################################
# Rewrite Dockerfile FROM lines based on features (unordered).
# Preserves the order of features as they appear in the Dockerfile.
# Updates the global $combination variable.
#######################################
compose_dockerfile() {
    local selected=("$@")
    declare -A is_selected

    # Mark selected features for quick lookup
    for feat in "${selected[@]}"; do
        is_selected["$feat"]=1
    done

    combination=""
    local previous=""
    local first_match=true
    local used=()

    while IFS= read -r line; do
        # Match FROM base AS <stage>
        if [[ "$line" =~ ^FROM[[:space:]]+base[[:space:]]+AS[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
            local stage="${BASH_REMATCH[1]}"

            # If this stage is one of the requested features
            if [[ ${is_selected[$stage]+_} ]]; then
                used+=("$stage")
                if $first_match; then
                    echo "$line"
                    previous="$stage"
                    first_match=false
                else
                    # Chain previous stage -> new combo name
                    local new_combo
                    IFS=-; new_combo="${used[*]}"; unset IFS
                    echo "FROM ${previous} AS ${new_combo}"
                    previous="$stage"
                fi
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done

    # Build global combination string from ordered "used" list
    if [[ ${#used[@]} -gt 0 ]]; then
        combination="${used[0]}"
        for ((i=1; i<${#used[@]}; i++)); do
            combination="${combination}-${used[i]}"
        done
    fi
}

features=()
docker_args=()

# Split into features (before --) and docker args (after --)
before_double_dash=true
for arg in "$@"; do
    if $before_double_dash && [[ "$arg" == "--" ]]; then
        before_double_dash=false
        continue
    fi

    if $before_double_dash; then
        features+=("$arg")
    else
        docker_args+=("$arg")
    fi
done

# If no features were specified → TARGET = base
if [[ ${#features[@]} -eq 0 ]]; then
    revised_dockerfile=$(cat "$SCRIPT_DIR/Dockerfile")
    TARGET="default"
else
    # Rewrite Dockerfile to create the proper combination chain
    revised_dockerfile=$(compose_dockerfile "${features[@]}" < "$SCRIPT_DIR/Dockerfile")
    # rerun to udpate combination variable
    compose_dockerfile "${features[@]}" < "$SCRIPT_DIR/Dockerfile" > /dev/null
    TARGET="$combination"
    echo "Target combination: $TARGET"
fi

# Info about args after --
if [[ ${#docker_args[@]} -gt 0 ]]; then
    echo "Using extra args: ${docker_args[*]}"
fi

docker image list | grep "nvim-dev-container-$TARGET" > /dev/null ||
	(echo "Rebuilding $TARGET" &&
		( echo "$revised_dockerfile" | docker build -f - --tag "nvim-dev-container-$TARGET" --target $TARGET $SCRIPT_DIR)
	)

VOLUME_TARGET_PATH="/app"
# Run the container
docker run -it --rm \
    -w "$VOLUME_TARGET_PATH" \
    --network host \
    --entrypoint /bin/zsh \
    "${DOCKER_DISPLAY_ARGS[@]}" \
    -e "HOST_OS=$HOST_OS" \
    -e "HOST_PWD=$(pwd)" \
    -e "VOLUME_TARGET_PATH=$VOLUME_TARGET_PATH" \
    -v ".:$VOLUME_TARGET_PATH" \
    -v "$HOME/.gitconfig:/home/user/.gitconfig" \
    -v "$HOME/.ssh:/home/user/.ssh:ro" \
    "${docker_args[@]}" \
    "nvim-dev-container-$TARGET" \
    --login
# a login shell is needed so that profile scripts are run
