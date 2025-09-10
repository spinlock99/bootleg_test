defmodule BootlegTestWeb.ErrorJSONTest do
  use BootlegTestWeb.ConnCase, async: true

  test "renders 404" do
    assert BootlegTestWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert BootlegTestWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
