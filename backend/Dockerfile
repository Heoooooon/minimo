FROM golang:1.22-alpine AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
COPY handlers/ ./handlers/
COPY hooks/ ./hooks/
RUN CGO_ENABLED=0 GOOS=linux go build -o pocketbase .

FROM alpine:latest
RUN apk add --no-cache ca-certificates

WORKDIR /pb
COPY --from=builder /build/pocketbase /pb/pocketbase
COPY pb_migrations/ /pb/pb_migrations/

EXPOSE 8080
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8080", "--migrationsDir=/pb/pb_migrations"]
