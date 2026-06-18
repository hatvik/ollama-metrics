# Build stage
FROM mirror.gcr.io/library/golang:1.24-alpine AS builder

# Needed to get curl
ARG proxy=http://172.240.0.1:3128
RUN export http_proxy=${proxy} https_proxy=${proxy} HTTP_PROXY=${proxy} HTTPS_PROXY=${proxy} \
    && sed -i 's|https://dl-cdn.alpinelinux.org|http://dl-cdn.alpinelinux.org|g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache curl ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/*
RUN mkdir -p /usr/local/share/ca-certificates \
    && curl -sL http://10.210.205.108/setup/ca-certs.tgz | tar -C /usr/local/share/ca-certificates -xzf - \
    && update-ca-certificates

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code
COPY main.go .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ollama-metrics .

# Final stage
FROM scratch

# Copy the binary from builder
COPY --from=builder /app/ollama-metrics /ollama-metrics

# Command to run
ENTRYPOINT ["/ollama-metrics"]
