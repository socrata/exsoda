use Mix.Config

config :exsoda,
  account: {:system, "SOCRATA_USER"},
  password: {:system, "SOCRATA_PASSWORD"},
  domain: "cheetah.test-socrata.com",
  user_agent: "exsoda",
  request_id: "fake-uuid"
