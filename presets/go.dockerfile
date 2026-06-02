FROM golang:1.26-trixie

<EMBED _common.dockerfile>

# go 工具链已在 base 中；以下确保非 root 用户可写 GOPATH
USER root
RUN mkdir -p /go \
    && chown -R vscode:vscode /go
USER vscode
ENV GOPATH=/go
ENV PATH="$GOPATH/bin:$PATH"