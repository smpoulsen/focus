defmodule Functorial.Lens do
  alias Functorial.Lens

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
      getter: fn structure -> get_in(structure, path) end,
      setter: fn f ->
        fn structure ->
          put_in(structure, path, f)
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
      setter.(f.(d)).(structure)
    end
  end

  @doc """
    Update the part of a data structure the lens focuses on.
  """
  @spec over(Lens.t, any, traversable) :: traversable
  def set(%Lens{setter: setter} = lens, val, structure) do
    with {:ok, _d} <- Lens.view(lens, structure) do
      setter.(val).(structure)
    end
  end
end
