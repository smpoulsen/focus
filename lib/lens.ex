defmodule Functorial.Lens do
  alias Functorial.Lens

  @doc """
    Define a lens to focus on a part of a data structure.
  """
  def lens(path) do
    {
      fn structure -> get_in(structure, path) end,
      fn f ->
        fn structure ->
          put_in(structure, path, f)
        end
      end
    }
  end

  @doc """
    Get a piece of a data structure that a lens focuses on.
  """
  def view({getter, _setter}, structure) do
    res = getter.(structure)
    case res do
      nil -> {:error, :bad_arg}
      _   -> {:ok, res}
    end
  end

  @doc """
    Modify the part of a data structure that a lens focuses on.
  """
  def over({_getter, setter} = lens, f, structure) do
    with {:ok, d} <- Lens.view(lens, structure) do
      setter.(f.(d)).(structure)
    end
  end

  @doc """
    Update the part of a data structure the lens focuses on.
  """
  def set({_getter, setter} = lens, val, structure) do
    with {:ok, _d} <- Lens.view(lens, structure) do
      setter.(val).(structure)
    end
  end
end
