defmodule Vahter.Repo do
  use Ecto.Repo,
    otp_app: :vahter,
    adapter: Ecto.Adapters.SQLite3
end
