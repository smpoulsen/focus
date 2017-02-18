defmodule Focus.Lens do
  alias Focus.Lens

  @moduledoc """
  Experimenting with functional lenses.
  """

  @enforce_keys [:getter, :setter]
  defstruct [:getter, :setter]

  @type t :: %Lens{
    getter: ((any) -> any),
    setter: (((any) -> any) -> any)
  }
  @type traversable :: map | list | tuple

  @doc """
  Define a lens to focus on a part of a data structure.

  ## Examples

      iex> alias Focus.Lens
      iex> person = %{name: "Homer"}
      iex> nameLens = Lens.makeLens(:name)
      iex> nameLens.getter.(person)
      "Homer"
      iex> nameLens.setter.(person).("Bart")
      %{name: "Bart"}
  """
  @spec makeLens(list) :: Lens.t
  def makeLens(path) do
    %Lens{
      getter: fn s -> getter(s, path) end,
      setter: fn s ->
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
  Compose with most general lens on the left

  ## Examples

      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> addressLens = Lens.makeLens(:address)
      iex> streetLens = Lens.makeLens(:street)
      iex> composed = Lens.compose(addressLens, streetLens)
      iex> Lens.view(composed, marge)
      {:ok, "123 Fake St."}
  """
  def compose(%Lens{getter: get_x, setter: set_x}, %Lens{getter: get_y, setter: set_y}) do
    %Lens{
      getter: fn s ->
        get_y.(get_x.(s))
      end,
      setter: fn s ->
        fn f ->
          set_x.(s).(set_y.(get_x.(s)).(f))
        end
      end
    }
  end

  @doc """
  Infix lens composition

  ## Examples
      iex> import Focus.Lens
      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{
      ...>   local: %{number: 123, street: "Fake St."},
      ...>   city: "Springfield"}
      ...> }
      iex> addressLens = Lens.makeLens(:address)
      iex> localLens = Lens.makeLens(:local)
      iex> streetLens = Lens.makeLens(:street)
      iex> addressLens ~> localLens ~> streetLens |> Lens.view!(marge)
      "Fake St."
  """
  def x ~> y do
    Lens.compose(x, y)
  end

  @doc """
  Get a piece of a data structure that a lens focuses on.

  ## Examples

      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> nameLens = Lens.makeLens(:name)
      iex> Lens.view!(nameLens, marge)
      "Marge"
  """
  @spec view!(Lens.t, traversable) :: any | nil
  def view!(%Lens{getter: getter}, structure) do
    getter.(structure)
  end

  @doc """
  Get a piece of a data structure that a lens focuses on;
  returns {:ok, data} | {:error, :bad_lens_path}

  ## Examples

      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> nameLens = Lens.makeLens(:name)
      iex> Lens.view(nameLens, marge)
      {:ok, "Marge"}
  """
  @spec view(Lens.t, traversable) :: {:error, :bad_arg} | {:ok, any}
  def view(%Lens{} = lens, structure) do
    res = view!(lens, structure)
    case res do
      nil -> {:error, :bad_lens_path}
      _   -> {:ok, res}
    end
  end


  @doc """
  Modify the part of a data structure that a lens focuses on.

  ## Examples
      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> nameLens = Lens.makeLens(:name)
      iex> Lens.over(nameLens, marge, &String.upcase/1)
      %{name: "MARGE", address: %{street: "123 Fake St.", city: "Springfield"}}
  """
  @spec over(Lens.t, traversable, (any -> any)) :: traversable
  def over(%Lens{setter: setter} = lens, structure, f) do
    with {:ok, d} <- Lens.view(lens, structure) do
      setter.(structure).(f.(d))
    end
  end

  @doc """
  Update the part of a data structure the lens focuses on.

  ## Examples

      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> nameLens = Lens.makeLens(:name)
      iex> Lens.set(nameLens, marge, "Homer")
      %{name: "Homer", address: %{street: "123 Fake St.", city: "Springfield"}}

      iex> alias Focus.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> addressLens = Lens.makeLens(:address)
      iex> streetLens = Lens.makeLens(:street)
      iex> composed = Lens.compose(addressLens, streetLens)
      iex> Lens.set(composed, marge, "42 Wallaby Way")
      %{name: "Marge", address: %{street: "42 Wallaby Way", city: "Springfield"}}
  """
  @spec set(Lens.t, traversable, any) :: traversable
  def set(%Lens{setter: setter} = lens, structure, val) do
    with {:ok, _d} <- Lens.view(lens, structure) do
      setter.(structure).(val)
    end
  end
end
