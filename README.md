# codexでswiftをbuild, testする環境

## Docker

```shell
docker run --rm -it \
  -v "${HOME}/.codex":/swiftlover/.codex \
  -v "$(pwd)":/swiftlover/workspace \
  -w /swiftlover/workspace \
  swift-codex:latest bash
```

## Containerization Framework

```shell
container system start
container image pull lemonaderoom/swift-codex
container run --rm -i -t \
  --volume "${HOME}/.codex":/swiftlover/.codex \
  --volume "$(pwd)":/swiftlover/workspace \
  --cpus 8 \
  --memory 16g \
  lemonaderoom/swift-codex bash
```

## Push

```shell
docker build -t swift-codex:latest -f ./Dockerfile .
docker login
docker tag swift-codex:latest lemonaderoom/swift-codex:latest
docker push lemonaderoom/swift-codex:latest
```