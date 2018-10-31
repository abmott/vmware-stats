FROM ruby

RUN \
  apt-get update && \
    gem install rbvmomi && \
  rm -rf /var/lib/apt/lists/*
