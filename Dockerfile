# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.4
FROM ruby:${RUBY_VERSION}-slim AS base

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development" \
    RAILS_ENV=test

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libsqlite3-dev libyaml-dev pkg-config curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

FROM base AS builder

ENV BUNDLE_WITHOUT=""

COPY Gemfile Gemfile.lock two_step.gemspec Rakefile ./
COPY lib/two_step/version.rb ./lib/two_step/version.rb
COPY lib ./lib
COPY app ./app
COPY config ./config

RUN bundle install

COPY . .

FROM builder AS test

ENV COVERAGE=1

RUN mkdir -p test/dummy/storage && \
    cd test/dummy && bundle exec rails db:create db:migrate

CMD ["bundle", "exec", "rake", "test"]

FROM base AS release

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

LABEL org.opencontainers.image.source="https://github.com/Galaxy-Group-GG/two_step" \
      org.opencontainers.image.description="TwoStep Rails engine — TOTP two-factor authentication"

# Default image target runs the test suite (CI / quality gate).
FROM test
