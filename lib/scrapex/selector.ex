defmodule Scrapex.Selector do

  # iex> Floki.parse("<div class=js-action>hello world</div>")
      # {"div", [{"class", "js-action"}], ["hello world"]}
      # iex> Floki.parse("<div>first</div><div>second</div>")
      # [{"div", [], ["first"]}, {"div", [], ["second"]}]
      
  def css(html, selector) do
    Floki.find(html, selector)
  end

  def attribute(tree, attr) do
    Floki.attribute(tree, attr)
  end
  
  
end