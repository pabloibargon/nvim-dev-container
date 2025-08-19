TARGET=${1:-"base"}
docker run -it --rm -w /app --entrypoint /bin/bash -v .:/app "nvim-dev-container-$TARGET" --login
# a login shell is needed so that profile scripts are run
