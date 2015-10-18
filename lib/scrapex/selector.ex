defmodule Scrapex.Selector do
  @moduledoc """
  Utilities for extracting data from markup language.
  """
  
  use GenServer
  alias Scrapex.Selector

  defstruct tree: []
  @type t :: %__MODULE__{tree: html_tree}

  @typedoc "A tree of HTML nodes, or a node itself if only one"
  @type html_tree :: html_node | [html_node]
  @typedoc "Name of the tag or attribute"
  @type name :: binary
  @typedoc "Attribute of a node"
  @type attribute :: {name, binary}

  @type html_node :: {name, [attribute], children}
  @type children :: [html_node]

  @type selector :: binary

  @doc """
  Generates a selection for a particular selector.

  The return value is a Selector.t
  """
  @spec select(binary | t, selector) :: t
  def select(html, selector) when is_binary(html) do
    %Selector{tree: Floki.parse(html)}
    |> select(selector)
  end
  def select(%Selector{tree: tree}, selector) do
    %Selector{tree: Floki.find(tree, selector)}
  end

  @doc """
  Extracts content or attribute value for a selection.
  """
  @spec extract(t, name) :: [binary]
  def extract(selector), do: extract(selector, "text")
  def extract(%Selector{tree: tree}, "text") do
    Enum.map(tree, fn({_, _, children}) -> 
      extract_text(children, "")
      |> String.strip
    end)
  end
  def extract(%Selector{tree: tree}, attr) do
    Floki.attribute(tree, attr)
  end

  defp extract_text(children), do: extract_text(children, "")
  defp extract_text([], result), do: result
  defp extract_text([text|rest], result) 
  when is_binary(text) 
  do
    extract_text(rest, result <> text)
  end
  defp extract_text([{_, _, children}|rest], result) do
    extract_text(rest, result <> extract_text(children))
  end
  
  defimpl Enumerable, for: __MODULE__ do
    alias Scrapex.Selector

    def count(%Selector{tree: tree}), do: length(tree)
    def member?(api = %Selector{}, selector) do
      Selector.select(api, selector) !== []
    end

    def reduce(_api, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(api, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(api, &1, fun)}
    end
    def reduce(%Selector{tree: []}, {:cont, acc}, _fun) do
      {:done, acc}
    end
    def reduce(%Selector{tree: [h | t]}, {:cont, acc}, fun) do
      new_acc = fun.(%Selector{tree: [h]}, acc)
      reduce(%Selector{tree: t}, new_acc, fun)
    end
  end
end