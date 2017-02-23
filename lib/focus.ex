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

  @moduledoc "Common functions usable by lenses, prisms, and traversals."

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
  @spec compose(Types.optic, Types.optic) :: Types.optic
  def compose(%{get: get_x, put: set_x}, %{get: get_y, put: set_y}) do
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
  @spec (Types.optic) ~> (Types.optic) :: Types.optic
  def x ~> y do
    compose(x, y)
  end

  @doc """
  Compose a pair of lenses to operate at the same level as one another.
  Calling Focus.view/2, Focus.over/3, or Focus.set/3 on an alongside composed
  pair returns a two-element tuple of the result.

  ## Examples

      iex> nums = [1,2,3,4,5,6]
      iex> Focus.alongside(Prism.make_prism(0), Prism.make_prism(3))
      ...> |> Focus.view(nums)
      {1, 4}

      iex> bart = %{name: "Bart", parents: {"Homer", "Marge"}, age: 10}
      iex> Focus.alongside(Lens.make_lens(:name), Lens.make_lens(:age))
      ...> |> Focus.view(bart)
      {"Bart", 10}
  """
  @spec alongside(Types.optic, Types.optic) :: Types.optic
  def alongside(%{get: get_x, put: set_x}, %{get: get_y, put: set_y}) do
    %Lens{
      get: fn s ->
      {get_x.(s), get_y.(s)}
    end,
      put: fn s ->
        fn f ->
          {set_x.(s).(f), set_y.(s).(f)}
        end
      end
    }
  end

  @doc """
  Given a list of lenses and a structure, apply Focus.view for each lens
  to the structure.

  ## Examples

      iex> homer = %{
      ...>   name: "Homer",
      ...>   job: "Nuclear Safety Inspector",
      ...>   children: ["Bart", "Lisa", "Maggie"]
      ...> }
      iex> lenses = [Lens.make_lens(:name), Lens.make_lens(:children)]
      iex> Focus.apply_list(lenses, homer)
      ["Homer", ["Bart", "Lisa", "Maggie"]]
  """
  @spec apply_list(list(Types.optic), Types.traversable) :: [any]
  def apply_list(lenses, structure) when is_list(lenses) do
    for lens <- lenses do
      Focus.view(lens, structure)
    end
  end

  @doc """
  Check whether an optic target is present in a data structure.

  ## Examples

      iex> first_elem = Prism.idx(1)
      iex> first_elem |> Focus.has([0])
      false

      iex> name = Lens.make_lens(:name)
      iex> name |> Focus.has(%{name: "Homer"})
      true
  """
  @spec has(Types.optic, Types.traversable) :: bool
  def has(optic, structure) do
    case Focus.view(optic, structure) do
      nil -> false
      {:error, _} -> false
      _   -> true
    end
  end

  @doc """
  Check whether an optic target is not present in a data structure.

  ## Examples

  iex> first_elem = Prism.idx(1)
  iex> first_elem |> Focus.hasnt([0])
  true

  iex> name = Lens.make_lens(:name)
  iex> name |> Focus.hasnt(%{name: "Homer"})
  false
  """
  @spec hasnt(Types.optic, Types.traversable) :: bool
  def hasnt(optic, structure), do: !has(optic, structure)
end
