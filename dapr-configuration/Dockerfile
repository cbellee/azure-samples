FROM golang:alpine as builder
WORKDIR /app
COPY  /src .
RUN go mod download
RUN go build -o ./main ./cmd/main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 8080
ENTRYPOINT ["/app/main"]
