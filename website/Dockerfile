# Build stage
FROM hexpm/elixir:1.18 AS build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Copy source code
COPY src ./src

# Compile the project
RUN mix compile

# Runtime stage
FROM hexpm/elixir:1.18

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

# Copy from build stage
COPY --from=build /app/_build /app/_build
COPY --from=build /app/deps /app/deps
COPY --from=build /app/src /app/src
COPY --from=build /app/mix.exs /app/mix.lock ./

# Install hex and rebar in runtime
RUN mix local.hex --force && \
    mix local.rebar --force

# Expose port
EXPOSE 4000

# Start command
CMD ["mix", "nex.start"]
