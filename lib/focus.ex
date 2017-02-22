defprotocol Focusable do
  @doc "View the data that an optic focuses on."
  def view(optic, structure)

  @doc "Modify the data that an optic focuses on."
  def over(optic, structure, f)

  @doc "Set the data that an optic focuses on."
  def set(optic, structure, value)
end

defmodule Focus do
  alias Focus.Types

  @spec view(Types.optic, Types.traversable) :: any | nil
  def view(optic, structure) do
    Focusable.view(optic, structure)
  end

  @spec over(Types.optic, Types.traversable, ((any) -> any)) :: Types.traversable
  def over(optic, structure, f) do
    Focusable.over(optic, structure, f)
  end

  def set(optic, structure, v) do
    Focusable.set(optic, structure, v)
  end

  @doc """
  Compose with most general lens on the left

  ## Examples

      iex> marge = %{
      ...>   name: "Marge",
      ...>   address: %{
      ...>     street: "123 Fake St.",
      ...>     city: "Springfield"
      ...>   }
      ...> }
      iex> address_lens = Lens.make_lens(:address)
      iex> street_lens = Lens.make_lens(:street)
      iex> composed = Focus.compose(address_lens, street_lens)
      iex> Focus.view(composed, marge)
      "123 Fake St."
  """
  def compose(%Lens{get: get_x, put: set_x}, %Lens{get: get_y, put: set_y}) do
    %Lens{
      get: fn s ->
      get_y.(get_x.(s))
    end,
      put: fn s ->
        fn f ->
          set_x.(s).(set_y.(get_x.(s)).(f))
        end
      end
    }
  end

  @doc """
  Infix lens composition

  ## Examples

      iex> import Focus
      iex> marge = %{name: "Marge", address: %{
      ...>   local: %{number: 123, street: "Fake St."},
      ...>   city: "Springfield"}
      ...> }
      iex> address_lens = Lens.make_lens(:address)
      iex> local_lens = Lens.make_lens(:local)
      iex> street_lens = Lens.make_lens(:street)
      iex> address_lens ~> local_lens ~> street_lens |> Focus.view(marge)
      "Fake St."
  """
  def x ~> y do
    compose(x, y)
  end
end
