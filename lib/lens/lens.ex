defmodule Lens do
  alias Focus.Types

  @moduledoc """
  Lenses combine getters and setters for keys in data structures.

  Lenses should match/operate over a single value in a data structure,
  e.g. a key in a map/struct.
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
      iex> name_lens |> Focus.view(person)
      "Homer"
      iex> name_lens |> Focus.set(person, "Bart")
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
  defp getter(s, x) when is_tuple(s), do: elem(s, x)
  defp getter(s, x) when is_list(s) do
    if Keyword.keyword?(s) do
      Keyword.get(s, x)
    else
      get_in(s, [Access.at(x)])
    end
  end
  defp getter(_, _), do: {:error, {:lens, :bad_data_structure}}

  defp setter(s, x, f) when is_map(s), do: Map.put(s, x, f)
  defp setter(s, x, f) when is_list(s) do
    if Keyword.keyword?(s) do
      Keyword.put(s, x, f)
    else
      List.replace_at(s, x, f)
    end
  end
  defp setter(s, x, f) when is_tuple(s) do
    s
    |> Tuple.delete_at(x)
    |> Tuple.insert_at(x, f)
  end
  defp setter(_s, _x, _f), do: {:error, {:lens, :bad_data_structure}}

  @doc """
  Automatically generate the valid lenses for the supplied map-like data structure.

  ## Examples

      iex> lisa = %{name: "Lisa", pets: %{cat: "Snowball"}}
      iex> lisa_lenses = Lens.make_lenses(lisa)
      iex> lisa_lenses.name
      ...> |> Focus.view(lisa)
      "Lisa"
      iex> pet_lenses = Lens.make_lenses(lisa.pets)
      iex> lisa_lenses.pets
      ...> ~> pet_lenses.cat
      ...> |> Focus.set(lisa, "Snowball II")
      %{name: "Lisa", pets: %{cat: "Snowball II"}}
  """
  @spec make_lenses(Types.traversable) :: %{optional(atom) => Lens.t, optional(String.t) => Lens.t}
  def make_lenses(%{} = structure) do
    for key <- Map.keys(structure), into: %{} do
      {key, Lens.make_lens(key)}
    end
  end

  @doc """
  A lens that focuses on an index in a list.

  ## Examples

      iex> first_elem = Lens.idx(0)
      iex> first_elem |> Focus.view([1,2,3,4,5])
      1

      iex> bad_index = Lens.idx(10)
      iex> bad_index |> Focus.view([1,2,3])
      nil
  """
  @spec idx(number) :: Lens.t
  def idx(num) when is_number(num), do: make_lens(num)

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
    def view(%Lens{get: get}, structure), do: get.(structure)

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
        iex> composed = Focus.compose(address_lens, street_lens)
        iex> Focus.set(composed, marge, "42 Wallaby Way")
        %{name: "Marge", address: %{street: "42 Wallaby Way", city: "Springfield"}}
    """
    @spec set(Lens.t, Types.traversable, any) :: Types.traversable
    def set(%Lens{put: setter} = lens, structure, val) do
      with {:ok, _d} <- Lens.safe_view(lens, structure) do
        setter.(structure).(val)
      end
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
      nil -> {:error, {:lens, :bad_path}}
      _   -> {:ok, res}
    end
  end
end
