use Mix.Config

config :exsoda,
  account: System.get_env("SOCRATA_USER"),
  password: System.get_env("SOCRATA_PASS"),
  domain: "soda.demo.socrata.com"
