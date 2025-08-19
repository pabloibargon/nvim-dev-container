TARGET=${1:-"base"}
docker rmi "nvim-dev-container-$TARGET"
docker build . --tag "nvim-dev-container-$TARGET" --target $TARGET

