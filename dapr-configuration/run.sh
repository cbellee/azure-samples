cd ./src
dapr run --app-id dapr-config --app-protocol grpc --app-port 8080 --resources-path ../manifests -- go run ./cmd/main.go
