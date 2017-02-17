defmodule Functorial.Lens do
  alias Functorial.Lens
  import Functorial

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
  """
  @spec makeLens(list) :: Lens.t
  def makeLens(path) do
    %Lens{
      getter: fn s-> getter(s, path) end,
      setter: fn s ->
        fn f->
          setter(s, path, f)
        end
      end
    }
  end

  defp getter(%{__struct__: _} = s, a), do: Map.get(s, a)
  defp getter(s, a) when is_map(s), do: Access.get(s, a)
  defp getter(s, a) when is_list(s), do: get_in(s, [Access.at(a)])
  defp getter(s, a) when is_tuple(s), do: Access.get(s, Access.elem(a))

  defp setter(s, a, f) when is_map(s), do: Map.put(s, a, f)
  defp setter(s, a, f) when is_list(s), do: List.replace_at(s, a, f)
  defp setter(s, a, f) when is_tuple(s) do
    Tuple.delete_at(s, a)
    Tuple.insert_at(s, a, f)
  end

  @doc """
  Compose with most general lens on the left

  ## Examples

      iex> alias Functorial.Lens
      iex> marge = %{name: "Marge", address: %{street: "123 Fake St.", city: "Springfield"}}
      iex> addressLens = Lens.makeLens(:address)
      iex> streetLens = Lens.makeLens(:street)
      iex> composed = Lens.compose(addressLens, streetLens)
      iex> Lens.view(composed, marge)
      {:ok, "123 Fake St."}
  """
  def compose(%Lens{getter: g_a, setter: s_a}, %Lens{getter: g_b, setter: s_b}) do
    %Lens{
      getter: fn s ->
        g_b.(g_a.(s))
      end,
      setter: fn s ->
        fn f ->
          s_a.(s).(s_b.(g_a.(s)).(f))
        end
      end
    }
  end

  @doc """
  Get a piece of a data structure that a lens focuses on.
  """
  @spec view(Lens.t, traversable) :: {:error, :bad_arg} | {:ok, any}
  def view(%Lens{getter: getter}, structure) do
    res = getter.(structure)
    case res do
      nil -> {:error, :bad_arg}
      _   -> {:ok, res}
    end
  end

  @doc """
    Modify the part of a data structure that a lens focuses on.
  """
  @spec over(Lens.t, (any -> any), traversable) :: traversable
  def over(%Lens{setter: setter} = lens, f, structure) do
    with {:ok, d} <- Lens.view(lens, structure) do
      setter.(structure).(f.(d))
    end
  end

  @doc """
  Update the part of a data structure the lens focuses on.
  """
  @spec set(Lens.t, any, traversable) :: traversable
  def set(%Lens{setter: setter} = lens, val, structure) do
    with {:ok, _d} <- Lens.view(lens, structure) do
      setter.(structure).(val)
    end
  end
end
