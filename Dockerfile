############################
# STEP 1 build executable binary
############################
FROM golang:alpine as builder
# Install git + SSL ca certificates.
# Git is required for fetching the dependencies.
# Ca-certificates is required to call HTTPS endpoints.
RUN apk update && apk add --no-cache git ca-certificates && update-ca-certificates
# Create appuser
RUN adduser -D -g '' appuser
WORKDIR $GOPATH/src/mypackage/myapp/
COPY . .
# Using go get.
RUN cd cmd/server; go get -d -v
# Fetch dependencies.
# Using go mod with go 1.11+
#RUN go mod download
# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/bin/webrtc_server-linux-amd64 -ldflags="-w -s" cmd/server/main.go
############################
# STEP 2 build a small image
############################
FROM scratch
WORKDIR /go
# Import from builder.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /go/src/mypackage/myapp/web/ /go/web/
COPY --from=builder /go/src/mypackage/myapp/configs/ /go/configs/
# Copy our static executable
COPY --from=builder /go/bin/webrtc_server-linux-amd64 /go/webrtc_server-linux-amd64
# Use an unprivileged user.
USER appuser
# Run the binary.
CMD /go/webrtc_server-linux-amd64
ENTRYPOINT [ "/go/webrtc_server-linux-amd64" ]

