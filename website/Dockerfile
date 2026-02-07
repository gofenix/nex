FROM hexpm/elixir:1.18.1-erlang-27.2-alpine-3.21.0

RUN apk add --no-cache build-base git

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .
RUN mix compile

EXPOSE 4000

CMD ["mix", "nex.start"]
