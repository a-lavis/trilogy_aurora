ARG RUBY_VERSION=3.3

FROM ruby:${RUBY_VERSION}-alpine

ARG TRILOGY_VERSION

ENV TRILOGY_VERSION=$TRILOGY_VERSION

# Create application directory.
RUN mkdir /app
WORKDIR /app

# Install packages
RUN apk upgrade && apk add --update build-base git linux-headers libxml2-dev libxslt-dev mariadb-dev ruby-dev tzdata yaml-dev zlib-dev

# Deploy application
ADD . /app

# Install gems
RUN sh /app/bin/setup
