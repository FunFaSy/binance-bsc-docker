FROM golang:1.17-alpine as builder

RUN apk add --no-cache make gcc musl-dev linux-headers git bash wget curl

RUN git clone https://github.com/binance-chain/bsc /bsc && \
    cd /bsc && \
    make geth && \
    cp /bsc/build/bin/geth /usr/local/bin/geth

RUN cd / && \
    \
    wget   $(curl -s https://api.github.com/repos/binance-chain/bsc/releases/latest |grep browser_ |grep mainnet |cut -d\" -f4) && \
    wget   $(curl -s https://api.github.com/repos/binance-chain/bsc/releases/latest |grep browser_ |grep testnet |cut -d\" -f4) && \
    \
    tar cvf /transfer.tar /usr/local/bin/geth /*.zip


FROM alpine:latest

RUN apk add --no-cache ca-certificates wget curl jq tini

COPY --from=builder /transfer.tar /transfer.tar

RUN cd / \
 && tar xvf /transfer.tar \
 && rm /transfer.tar \
 && unzip /mainnet.zip -d /bsc_mainnet \
 && unzip /testnet.zip -d /bsc_testnet \
 && rm -f ./*.zip


COPY entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]

# NODE P2P
EXPOSE 30311/udp
EXPOSE 30311/tcp

# pprof / metrics
EXPOSE 6060/tcp

# HTTP based JSON RPC API
EXPOSE 8545/tcp
# WebSocket based JSON RPC API
EXPOSE 8546/tcp
# GraphQL API
EXPOSE 8547/tcp

ENTRYPOINT ["/entrypoint.sh"]