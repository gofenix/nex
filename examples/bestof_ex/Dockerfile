FROM elixir:1.18-alpine

RUN apk add --no-cache build-base git openssl ncurses-libs

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY . .

RUN mix deps.get

EXPOSE 4000

CMD ["mix", "nex.start"]
