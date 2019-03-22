FROM ruby:2.6.1

# Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

RUN     mkdir /openfarm
WORKDIR /openfarm

ENV  BUNDLE_PATH=/bundle BUNDLE_BIN=/bundle/bin GEM_HOME=/bundle
ENV  PATH="${BUNDLE_BIN}:${PATH}"
COPY ./Gemfile /openfarm
