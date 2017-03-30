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

  @doc "Wrapper around Focusable.view/2"
  @spec view(Types.optic, Types.traversable) :: any | nil
  def view(optic, structure) do
    Focusable.view(optic, structure)
  end

  @doc "Wrapper around Focusable.over/3"
  @spec over(Types.optic, Types.traversable, ((any) -> any)) :: Types.traversable
  def over(optic, structure, f) do
    Focusable.over(optic, structure, f)
  end

  @doc "Wrapper around Focusable.set/3"
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
      iex> Focus.alongside(Lens.idx(0), Lens.idx(3))
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
  Map a function that takes as its argument the value that an optic focuses on
  over a list of traversable structures. The function is applied each structure
  in the list that the lens focuses on; any list elements that don't have a match
  for the lens are passed through.

  ## Examples

      iex> family = [
      ...>   %{name: "Homer", pets: ["Snowball"]},
      ...>   %{name: "Marge", pets: ["Snowball"]},
      ...>   %{name: "Bart", pets: ["Snowball"]},
      ...>   %{name: "Lisa", pets: ["Snowball"]},
      ...>   %{other_key: "I'm not affected"},
      ...> ]
      iex> Lens.make_lens(:pets)
      ...> |> Focus.map(fn pets ->
      ...>   ["Santa's Little Helper" | pets]
      ...> end, family)
      [
        %{name: "Homer", pets: ["Santa's Little Helper", "Snowball"]},
        %{name: "Marge", pets: ["Santa's Little Helper", "Snowball"]},
        %{name: "Bart", pets: ["Santa's Little Helper", "Snowball"]},
        %{name: "Lisa", pets: ["Santa's Little Helper", "Snowball"]},
        %{other_key: "I'm not affected"},
      ]
      iex> Lens.make_lens(:name)
      ...> |> Focus.map(&(String.upcase(&1)), family)
      [
        %{name: "HOMER", pets: ["Snowball"]},
        %{name: "MARGE", pets: ["Snowball"]},
        %{name: "BART", pets: ["Snowball"]},
        %{name: "LISA", pets: ["Snowball"]},
        %{other_key: "I'm not affected"},
      ]

  """
  @spec map(Types.optic, fun, Types.traversable) :: Types.traversable
  def map(optic, f, structure) do
    for s <- structure do
      case Focus.view(optic, s) do
        nil -> s
        _ -> Focus.over(optic, s, f)
      end
    end
  end

  @doc """
  Given a list of lenses and a structure, apply Focus.view/2 for each lens
  to the structure.

  ## Examples

      iex> homer = %{
      ...>   name: "Homer",
      ...>   job: "Nuclear Safety Inspector",
      ...>   children: ["Bart", "Lisa", "Maggie"]
      ...> }
      iex> lenses = Lens.make_lenses(homer)
      iex> [lenses.name, lenses.children]
      ...> |> Focus.view_list(homer)
      ["Homer", ["Bart", "Lisa", "Maggie"]]
  """
  @spec view_list(list(Types.optic), Types.traversable) :: [any]
  def view_list(lenses, structure) when is_list(lenses) do
    for lens <- lenses do
      Focus.view(lens, structure)
    end
  end

  @doc """
  Check whether an optic's target is present in a data structure.

  ## Examples

      iex> first_elem = Lens.idx(1)
      iex> first_elem |> Focus.has([0])
      false

      iex> name = Lens.make_lens(:name)
      iex> name |> Focus.has(%{name: "Homer"})
      true
  """
  @spec has(Types.optic, Types.traversable) :: boolean
  def has(optic, structure) do
    case Focus.view(optic, structure) do
      nil -> false
      {:error, _} -> false
      _   -> true
    end
  end

  @doc """
  Check whether an optic's target is not present in a data structure.

  ## Examples

      iex> first_elem = Lens.idx(1)
      iex> first_elem |> Focus.hasnt([0])
      true

      iex> name = Lens.make_lens(:name)
      iex> name |> Focus.hasnt(%{name: "Homer"})
      false
  """
  @spec hasnt(Types.optic, Types.traversable) :: boolean
  def hasnt(optic, structure), do: !has(optic, structure)

  @doc """
  Partially apply a lens to Focus.over/3, fixing the lens argument and
  returning a function that takes a Types.traversable and an update function.

  ## Examples

      iex> upcase_name = Lens.make_lens(:name)
      ...> |> Focus.fix_over(&String.upcase/1)
      iex> %{name: "Bart", parents: {"Homer", "Marge"}}
      ...> |> upcase_name.()
      %{name: "BART", parents: {"Homer", "Marge"}}

      iex> fst = Lens.idx(0)
      iex> states = [:maryland, :texas, :illinois]
      iex> Focus.over(fst, states, &String.upcase(Atom.to_string(&1)))
      ["MARYLAND", :texas, :illinois]
  """
  @spec fix_over(Types.optic, ((any) -> any)) :: ((Types.traversable) -> Types.traversable)
  def fix_over(%{get: _, put: _} = lens, f \\ fn x -> x end) when is_function(f) do
    fn structure ->
      Focus.over(lens, structure, f)
    end
  end

  @doc """
  Partially apply a lens to Focus.set/3, fixing the optic argument and
  returning a function that takes a Types.traversable and a new value.

  ## Examples

      iex> name_setter = Lens.make_lens(:name)
      ...> |> Focus.fix_set
      iex> %{name: "Bart", parents: {"Homer", "Marge"}}
      ...> |> name_setter.("Lisa")
      %{name: "Lisa", parents: {"Homer", "Marge"}}

      iex> fst = Lens.idx(0)
      iex> states = [:maryland, :texas, :illinois]
      iex> Focus.over(fst, states, &String.upcase(Atom.to_string(&1)))
      ["MARYLAND", :texas, :illinois]
  """
  @spec fix_set(Types.optic) :: ((Types.traversable, any) -> Types.traversable)
  def fix_set(%{get: _, put: _} = lens) do
    fn structure, val ->
      Focus.set(lens, structure, val)
    end
  end

  @doc """
  Fix Focus.view/2 on a given optic. This partially applies Focus.view/2 with the given
  optic and returns a function that takes a Types.traversable structure.

  ## Examples

      iex> view_name = Lens.make_lens(:name)
      ...> |> Focus.fix_view
      iex> homer = %{name: "Homer"}
      iex> view_name.(homer)
      "Homer"
      iex> [homer, %{name: "Marge"}, %{name: "Bart"}]
      ...> |> Enum.map(&view_name.(&1))
      ["Homer", "Marge", "Bart"]
  """
  @spec fix_view(Types.optic) :: (Types.traversable -> any)
  def fix_view(%{get: _, put: _} = optic) do
    fn structure ->
      Focus.view(optic, structure)
    end
  end
end
