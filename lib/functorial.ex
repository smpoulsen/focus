defmodule Focus do
  @doc """
  Right to left function composition

  compose :: (b -> c) -> (a -> b) -> (a -> c)
  """
  @spec compose(function, function) :: function
  def compose(f, g) do
    fn arg -> f.(g.(arg)) end
  end
  def f <<< g, do: compose(f, g)

  def curry(f) do
    arity = :erlang.fun_info(f)[:arity]
    curry(f, arity, [])
  end

  @doc "Lift a value into the either {:ok, result} | {:error, reason} context (monad return)"
  def lift(x), do: {:ok, x}

  @doc """
  bind for the improvised either of {:ok, result} | {:error, reason}

  bind :: (a -> b) -> (a -> Either b reason)
  bind :: (a -> Either b reason) -> (b -> c) -> (a -> Either c reason)
  (~>) :: (a -> b) -> (a -> Either b reason)

  Ex:
  bind(fn x -> x + 1)
  (fn x -> {:ok, x + 3} |> bind(fn z -> z * 2)).(2) == 10
  """
  def bind(f) do
    fn x -> bind_helper(f, x) end
  end
  def bind(g, f) do
    fn x -> bind_helper(f, g.(x)) end
  end
  def f ~> g do
    bind(g) <<< f
  end

  defmacro flip(f, x, y) do
    quote do
      unquote(f).(unquote(y), unquote(x))
    end
  end

  def bind_helper(f, {:ok, x}), do: {:ok, f.(x)}
  def bind_helper(_f, {:error, msg}), do: {:error, msg}
  def bind_helper(_, _), do: {:error, %{bind: :badarg}}

  defp curry(f, 0, args) do
    apply(f, Enum.reverse(args))
  end
  defp curry(f, arity, args) do
    fn arg -> curry(f, arity - 1, [arg | args]) end
  end
end
