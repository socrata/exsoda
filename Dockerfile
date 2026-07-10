# syntax=docker/dockerfile:1

FROM socrata/runit-elixir-jammy:1.17 AS builder
WORKDIR /app
COPY . .
RUN mix deps.get
RUN mix hex.build

# Stage 2: Target for export
FROM scratch AS export-stage
COPY --from=builder /app/ /
