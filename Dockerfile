# build proxy and webserv
FROM golang:alpine AS gobuilder

RUN apk update && apk upgrade && apk add git

# Official web irc gateway repo
RUN git clone https://github.com/kiwiirc/webircgateway /build

WORKDIR /build

RUN CGO_ENABLED=0 GOOS=linux go build 

# Build front end irc web client
FROM node:19-alpine AS wwwbuilder

# For some reason, one of the node packages
# is using git for something. This fixes an
# error related to that.
RUN apk update && apk upgrade && apk add git

# Custom front end build
COPY . /build

WORKDIR /build

RUN yarn install && yarn run build

# Build full application
FROM alpine:latest AS final

COPY --from=gobuilder /build/webircgateway /app/webircgateway
#
# Copy example conf to have a default
# To override: 
#    1. Bind Mount your custom config.conf
#        Ex. --mount --type=bind,source=./config.conf,target=/app/config.conf
#    2. add "--config=config.conf" to the end of the docker run command
# Remember: paths within the conf are relative to the conf itself
#  unless you specify an absolute path!
#
COPY --from=gobuilder /build/config.conf.example /app/config.conf.example

# copying in to this directory specifically for the default 
# when you pass in your custom config it should serve html content at www/
COPY --from=wwwbuilder /build/dist /app/www

WORKDIR /app

EXPOSE 80 443

ENTRYPOINT ["./webircgateway"]

# default argument to pass to webircgateway
CMD ["--config=config.conf.example"]
