defmodule BootlegTest.Repo do
  use Ecto.Repo,
    otp_app: :bootleg_test,
    adapter: Ecto.Adapters.Postgres
end
