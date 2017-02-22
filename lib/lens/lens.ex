defmodule Lens do
  alias Focus.Types

  @moduledoc """
  Lenses combine getters and setters for keys in data structures.
  """

  @enforce_keys [:get, :put]
  defstruct [:get, :put]

  @type t :: %Lens{
    get: ((any) -> any),
    put: (((any) -> any) -> any)
  }

  @doc """
  Define a lens to Focus on a part of a data structure.

  ## Examples

      iex> person = %{name: "Homer"}
      iex> name_lens = Lens.make_lens(:name)
      iex> name_lens.get.(person)
      "Homer"
      iex> name_lens.put.(person).("Bart")
      %{name: "Bart"}
  """
  @spec make_lens(list) :: Lens.t
  def make_lens(path) do
    %Lens{
      get: fn s -> getter(s, path) end,
      put: fn s ->
        fn f ->
          setter(s, path, f)
        end
      end
    }
  end

  defp getter(%{__struct__: _} = s, x), do: Map.get(s, x)
  defp getter(s, x) when is_map(s), do: Access.get(s, x)
  defp getter(s, x) when is_list(s), do: get_in(s, [Access.at(x)])
  defp getter(s, x) when is_tuple(s), do: elem(s, x)

  defp setter(s, x, f) when is_map(s), do: Map.put(s, x, f)
  defp setter(s, x, f) when is_list(s), do: List.replace_at(s, x, f)
  defp setter(s, x, f) when is_tuple(s) do
    s
    |> Tuple.delete_at(x)
    |> Tuple.insert_at(x, f)
  end

  @doc """
  Partially apply a lens to Focus.over/3, returning a function that takes a
  Types.traversable and an update function.

  ## Examples

  iex> upcase_name = Lens.make_lens(:name)
  ...> |> Lens.fix_over(&String.upcase/1)
  iex> %{name: "Bart", parents: {"Homer", "Marge"}}
  ...> |> upcase_name.()
  %{name: "BART", parents: {"Homer", "Marge"}}
  """
  @spec fix_over(Lens.t, ((any) -> any)) :: ((Types.traversable) -> Types.traversable)
  def fix_over(%Lens{} = lens, f \\ fn x -> x end) when is_function(f) do
    fn structure ->
      Focus.over(lens, structure, f)
    end
  end

  @doc """
  Partially apply a lens to Focus.set/3, returning a function that takes a
  Types.traversable and a new value.

  ## Examples

      iex> name_setter = Lens.make_lens(:name)
      ...> |> Lens.fix_set
      iex> %{name: "Bart", parents: {"Homer", "Marge"}}
      ...> |> name_setter.("Lisa")
      %{name: "Lisa", parents: {"Homer", "Marge"}}
  """
  @spec fix_set(Lens.t) :: ((Types.traversable, any) -> Types.traversable)
  def fix_set(%Lens{} = lens) do
    fn structure, val ->
      Focus.set(lens, structure, val)
    end
  end

  @doc """
  Get a piece of a data structure that a lens Focuses on;
  returns {:ok, data} | {:error, :bad_lens_path}

  ## Examples

      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> name_lens = Lens.make_lens(:name)
      iex> Lens.safe_view(name_lens, marge)
      {:ok, "Marge"}
  """
  @spec safe_view(Lens.t, Types.traversable) :: {:error, :bad_arg} | {:ok, any}
  def safe_view(%Lens{} = lens, structure) do
    res = Focus.view(lens, structure)
    case res do
      nil -> {:error, :bad_lens_path}
      _   -> {:ok, res}
    end
  end

  @doc """
  Fix Focus.view/2 on a given lens. This partially applies Focus.view/2 with the given
  lens and returns a function that takes a Types.traversable structure.

  ## Examples

      iex> view_name = Lens.make_lens(:name)
      ...> |> Lens.fix_view
      iex> homer = %{name: "Homer"}
      iex> view_name.(homer)
      "Homer"
      iex> [homer, %{name: "Marge"}, %{name: "Bart"}]
      ...> |> Enum.map(&view_name.(&1))
      ["Homer", "Marge", "Bart"]
  """
  @spec fix_view(Lens.t) :: (Types.traversable -> any)
  def fix_view(%Lens{} = lens) do
    fn structure ->
      Focus.view(lens, structure)
    end
  end

  @doc """
  Compose a pair of lenses to operate at the same level as one another.
  Calling Focus.view/2, Focus.over/3, or Focus.set/3 on an alongside composed
  pair returns a two-element tuple of the result.

  ## Examples

  iex> nums = [1,2,3,4,5,6]
  iex> Lens.alongside(Lens.make_lens(0), Lens.make_lens(3))
  ...> |> Focus.view(nums)
  {1, 4}

  iex> bart = %{name: "Bart", parents: {"Homer", "Marge"}, age: 10}
  iex> Lens.alongside(Lens.make_lens(:name), Lens.make_lens(:age))
  ...> |> Focus.view(bart)
  {"Bart", 10}
  """
  @spec alongside(Lens.t, Lens.t) :: Lens.t
  def alongside(%Lens{get: get_x, put: set_x}, %Lens{get: get_y, put: set_y}) do
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
      iex> Lens.apply_list(lenses, homer)
      ["Homer", ["Bart", "Lisa", "Maggie"]]
  """
  @spec apply_list(list(Lens.t), Types.traversable) :: [any]
  def apply_list(lenses, structure) when is_list(lenses) do
    for lens <- lenses do
      Focus.view(lens, structure)
    end
  end

  defimpl Focusable do
    @doc """
    View the data that an optic Focuses on.

    ## Examples

        iex> marge = %{
        ...>   name: "Marge",
        ...>   address: %{
        ...>     street: "123 Fake St.",
        ...>     city: "Springfield"
        ...>   }
        ...> }
        iex> name_lens = Lens.make_lens(:name)
        iex> Focus.view(name_lens, marge)
        "Marge"
    """
    @spec view(Lens.t, Types.traversable) :: any | nil
    def view(%Lens{get: get}, structure) do
      get.(structure)
    end

    @doc """
    Modify the part of a data structure that a lens Focuses on.

    ## Examples

        iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
        iex> name_lens = Lens.make_lens(:name)
        iex> Focus.over(name_lens, marge, &String.upcase/1)
        %{name: "MARGE", address: %{street: "123 Fake St.", city: "Springfield"}}
    """
    @spec over(Lens.t, Types.traversable, (any -> any)) :: Types.traversable
    def over(%Lens{put: setter} = lens, structure, f) do
      with {:ok, d} <- Lens.safe_view(lens, structure) do
        setter.(structure).(f.(d))
      end
    end

    @doc """
    Update the part of a data structure the lens Focuses on.

    ## Examples

        iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
        iex> name_lens = Lens.make_lens(:name)
        iex> Focus.set(name_lens, marge, "Homer")
        %{name: "Homer", address: %{street: "123 Fake St.", city: "Springfield"}}

        iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
        iex> address_lens = Lens.make_lens(:address)
        iex> street_lens = Lens.make_lens(:street)
        iex> composed = Focusable.compose(address_lens, street_lens)
        iex> Focus.set(composed, marge, "42 Wallaby Way")
        %{name: "Marge", address: %{street: "42 Wallaby Way", city: "Springfield"}}
    """
    @spec set(Lens.t, Types.traversable, any) :: Types.traversable
    def set(%Lens{put: setter} = lens, structure, val) do
      with {:ok, _d} <- Lens.safe_view(lens, structure) do
        setter.(structure).(val)
      end
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
        iex> composed = Focusable.compose(address_lens, street_lens)
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

    iex> import Focusable
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
end
