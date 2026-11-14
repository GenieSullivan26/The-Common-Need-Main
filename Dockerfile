# syntax=docker/dockerfile:1
FROM ruby:3.4-slim-bookworm AS base

WORKDIR /app

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    PORT="8080" \
    LOCAL_NODE_CODE="#OAK-01" \
    LOCAL_OSRM_URL="http://osrm:5000" \
    LOCAL_OLLAMA_URL="http://127.0.0.1:11434/api/generate"

# Install runtime dependencies for PostgreSQL 17 + PostGIS (GEOS, PROJ, GDAL) & Rails
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      libgeos-c1v5 \
      libpq5 \
      libproj25 \
      libvips \
      postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libgeos-dev \
      libpq-dev \
      libproj-dev \
      nodejs \
      npm \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile ./
COPY gems ./gems

RUN bundle config set --local deployment 'false' && \
    bundle check || true

COPY . .

FROM base

COPY --from=build /app /app

RUN useradd --create-home --shell /bin/bash decidim && \
    chown -R decidim:decidim /app
USER decidim:decidim

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/manifest.json || exit 1

CMD ["ruby", "bin/preview_server.rb"]
