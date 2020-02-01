FROM ruby:2.7.0

#  Ruby
#-----------------------------------------------
ENV BUNDLER_VERSION 2.0.2

RUN gem install bundler --version "$BUNDLER_VERSION" \
    # Ignore warning: "Don't run Bundler as root."
    # @see https://github.com/docker-library/rails/issues/10
    && bundle config --global silence_root_warning 1 \
    # Ignore insecure `git` protocol for gem
    && bundle config --global git.allow_insecure true

#  Timezone
#-----------------------------------------------
ENV TZ Asia/Tokyo

#  Locale
#-----------------------------------------------
RUN echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen \
    && apt-get update && apt-get install -y locales \
    && locale-gen ja_JP.UTF-8 \
    && update-locale LANG=ja_JP.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV LC_CTYPE=ja_JP.UTF-8

#  App
#-----------------------------------------------
WORKDIR /app
ENV PATH $PATH:/app/vendor/bundle/bin
ENV DOCKER_LOGS true

COPY Gemfile Gemfile.lock /app/

# As we vendor dependencies, we don't need gems in bundler system path (/usr/local/bundle)
ENV BUNDLE_PATH__SYSTEM=false

RUN bundle install \
    --path vendor/bundle \
    --binstubs vendor/bundle/bin \
    --without test development \
    --jobs 8

COPY . /app
CMD ["bundle", "exec", "ruby", "/app/salesforce-bulkapi-notifier.rb"]
