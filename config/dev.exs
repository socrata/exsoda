use Mix.Config

config :exsoda,
  domain: "localhost",
  host: "localhost",
  account: System.get_env("SOCRATA_LOCAL_USER"),
  password: System.get_env("LOCAL_PASS"),
  hackney_opts: [:insecure]
