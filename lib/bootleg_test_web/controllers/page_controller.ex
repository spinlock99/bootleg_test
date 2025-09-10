defmodule BootlegTestWeb.PageController do
  use BootlegTestWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
