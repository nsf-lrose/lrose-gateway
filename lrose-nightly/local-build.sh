#! /bin/bash

# Clean existing directory if it exists for a clean slate
[[ -d ./lrose-nightly ]] && rm -rf ./lrose-nightly

mkdir ./lrose-nightly

docker compose down
docker compose up -d

echo "See build logs in ./lrose-nightly/build-logs"
echo "Follow docker container stdout with by running:
docker logs lrose-nightly-lrose-build-1 -f"

read -p "Follow now? [Y/n] " FOLLOW
if [[ "$FOLLOW" != "n" ]]
then
  docker logs lrose-nightly-lrose-build-1 -f
fi
