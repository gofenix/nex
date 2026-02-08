FROM hexpm/elixir:1.18.1-erlang-27.2-alpine-3.21.0

RUN apk add --no-cache build-base git

WORKDIR /app

ENV MIX_ENV=prod

# Install hex + rebar (hexpm image has them, but force to ensure latest)
RUN mix local.hex --force && mix local.rebar --force

# Cache deps layer
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

# Copy source and compile
COPY . .
RUN mix compile

CMD ["mix", "nex.start"]
