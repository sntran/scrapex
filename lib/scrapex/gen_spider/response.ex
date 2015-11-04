defmodule Scrapex.GenSpider.Response do
  @moduledoc """
  Utilities for working response returned from `GenSpider`.
  """

  alias Scrapex.GenSpider.Response

  defstruct url: "", body: ""
  @type t :: %__MODULE__{url: binary, body: binary}

  @doc """
  Join a path relative to the response's URL.

  ## Examples

      iex> alias Scrapex.GenSpider.Response
      iex> response = %Response{url: "http://www.scrapex.com/subfolder"}
      iex> Response.url_join(response, "/subfolder2")
      "http://www.scrapex.com/subfolder2"
      iex> Response.url_join(response, "subsubfolder")
      "http://www.scrapex.com/subfolder/subsubfolder"
  """
  @spec url_join(t, binary) :: binary
  def url_join(%Response{url: url}, "/" <> path) do
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.authority}/#{path}" 
  end

  def url_join(%Response{url: url}, path) do
    "#{url}/#{path}"
  end

  def url_join(_, "http" <> path) do
    "http#{path}"
  end
end