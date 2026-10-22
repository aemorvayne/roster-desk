FROM ruby:4.0.7-slim AS builder
WORKDIR /app
ENV BUNDLE_WITHOUT=development:test
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 4.0.20 --no-document && bundle install

FROM ruby:4.0.7-slim
WORKDIR /app
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test PORT=10000
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 && rm -rf /var/lib/apt/lists/*
RUN useradd --create-home app && chown app:app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --chown=app:app . .
USER app
EXPOSE 10000
CMD ["sh", "-c", "bundle exec ruby bin/rails db:prepare && exec bundle exec puma -C config/puma.rb"]
