defmodule Prism do
  alias Focus.Types

  @moduledoc """
  Prisms are like lenses, but used when the view focused on may not exist.

  This includes sum types; although not backed by an explicit Maybe type,
  the [{:ok, any} | {:error}] convention is explicitly supported as a value that
  a prism can focus on.
  """

  @enforce_keys [:get, :put]
  defstruct [:get, :put]

  @type t :: %Prism{
    get: ((any) -> any),
    put: (((any) -> any) -> any)
  }

  @doc """
  Define a prism to focus on a part of a data structure.

  ## Examples

      iex> fst = Prism.make_prism(0)
      iex> states = [:maryland, :texas, :illinois]
      iex> fst.get.(states)
      :maryland
      iex> fst.put.(states).(:california)
      [:california, :texas, :illinois]
  """
  @spec make_prism(any) :: Prism.t
  defp make_prism(path) do
    %Prism{
      get: fn s -> getter(s, path) end,
      put: fn s ->
        fn f ->
          setter(s, path, f)
        end
      end
    }
  end

  defp getter(_s, _x), do: {:error, {:prism, :bad_data_structure}}
  defp setter(_s, _x, _f), do: {:error, {:prism, :bad_data_structure}}

  @doc """
  A prism that matches an {:ok, _} tuple.

  ## Examples

      iex> ok = Prism.ok
      iex> ok |> Focus.view({:ok, 5})
      {:ok, 5}
      iex> ok |> Focus.set({:ok, 5}, "Banana")
      {:ok, "Banana"}
      iex> ok |> Focus.view({:error, :oops})
      {:error, {:prism, :bad_path}}
  """
  @spec ok() :: Prism.t
  def ok() do
    %Prism{
      get: fn s -> get_ok(s) end,
      put: fn s ->
        fn f ->
          set_ok(s, f)
        end
      end
    }
  end
  defp get_ok({:ok, x}), do: x
  defp get_ok({:error, _}), do: nil
  defp set_ok({:ok, _x}, f), do: {:ok, f}

  @doc """
  A prism that matches an {:error, _} tuple.
  Note that on a successful match, view/set/over will
  return {:ok, _}

  ## Examples

      iex> error = Prism.error
      iex> error |> Focus.view({:error, 5})
      {:ok, 5}
      iex> error |> Focus.set({:error, 5}, "Banana")
      {:ok, "Banana"}
      iex> error |> Focus.view({:ok, :oops})
      {:error, {:prism, :bad_path}}
  """
  @spec error() :: Prism.t
  def error() do
    %Prism{
      get: fn s -> get_error(s) end,
      put: fn s ->
        fn f ->
          set_error(s, f)
        end
      end
    }
  end
  defp get_error({:error, x}), do: x
  defp get_error({:ok, _}), do: nil
  defp set_error({:error, _x}, f), do: {:ok, f}

  defimpl Focusable do
    @doc """
    Get a piece of a data structure that a prism focuses on;
    returns {:ok, data} | {:error, :bad_prism_path}

    ## Examples

        iex> ok = Prism.ok
        iex> ok |> Focus.view({:ok, 5})
        {:ok, 5}
    """
    @spec view(Prism.t, Types.traversable) :: {:error, {:prism, :bad_path}} | {:ok, any}
    def view(%Prism{get: get}, structure) do
      res = get.(structure)
      case res do
        nil -> {:error, {:prism, :bad_path}}
        _   -> {:ok, res}
      end
    end

    @doc """
    Modify the part of a data structure that a prism focuses on.

    ## Examples

        iex> ok = Prism.ok
        iex> ok |> Focus.over({:ok, "banana"}, &String.upcase/1)
        {:ok, "BANANA"}
    """
    @spec over(Prism.t, Types.traversable, (any -> any)) :: Types.traversable
    def over(%Prism{put: put} = prism, structure, f) do
      with {:ok, data_view} <- view(prism, structure) do
        put.(structure).(f.(data_view))
      end
    end

    @doc """
    Update the part of a data structure the prism focuses on.

    ## Examples

        iex> ok = Prism.ok
        iex> ok |> Focus.set({:ok, "banana"}, "pineapple")
        {:ok, "pineapple"}
    """
    @spec set(Prism.t, Types.traversable, any) :: Types.traversable
    def set(%Prism{put: put} = prism, structure, val) do
      with {:ok, _data_view} <- view(prism, structure) do
        put.(structure).(val)
      end
    end
  end
end
