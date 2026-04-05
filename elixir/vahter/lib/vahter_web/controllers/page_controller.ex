defmodule VahterWeb.PageController do
  use VahterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
