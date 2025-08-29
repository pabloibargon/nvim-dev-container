# Global var: will contain the final combined name
combination=""
# Function: compose_dockerfile
# Reads a Dockerfile from stdin and rewrites FROM lines based on selected features.
# Arguments: list of features (unordered)
compose_dockerfile() {
    local selected=("$@")
    declare -A is_selected

    # Mark selected features in an associative array for quick lookup
    for feat in "${selected[@]}"; do
        is_selected["$feat"]=1
    done

    local previous=""
    combination=""
    local first_match=true

    while IFS= read -r line; do
        # Match lines like: FROM base AS extraX
        if [[ "$line" =~ ^FROM[[:space:]]+base[[:space:]]+AS[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
            local stage="${BASH_REMATCH[1]}"
            if [[ ${is_selected[$stage]+_} ]]; then
                if $first_match; then
                    echo "$line"
                    previous="$stage"
                    combination="$stage"
                    first_match=false
                else
                    combination="${combination}-${stage}"
                    echo "FROM ${previous} AS ${combination}"
                    previous="$stage"
                fi
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done
}


# If args are given, use them; otherwise, use defaults
if [[ $# -eq 0 ]]; then
	revised_dockerfile=$(cat Dockerfile)
	TARGET="default"
else
	revised_dockerfile=$(compose_dockerfile "$@")
	TARGET=$combination 
fi
docker rmi "nvim-dev-container-$TARGET" 2> /dev/null
echo "$revised_dockerfile" | docker build . --tag "nvim-dev-container-$TARGET" --target $TARGET -

