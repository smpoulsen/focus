defmodule FunctorialTest do
  use ExUnit.Case
  import Functorial
  doctest Functorial

  test "compose/2 composes two functions" do
    f = fn x -> x + 2 end
    g = fn y -> y * 3 end
    f_of_g = Functorial.compose(f, g)

    assert f_of_g.(2) == 8
  end

  test "bind/1 works for the improvised either {:ok, result} | {:error, reason}" do
    x = {:ok, 4}
    y = {:error, :bad_arg}

    bound_square = Functorial.bind(fn z -> z * z end)
    assert bound_square.(x) == {:ok, 16}
    assert bound_square.(y) == {:error, :bad_arg}
  end

  test "bind/2 binds when piping" do
    f = fn x -> x * 3 end
    g = fn x -> x - 2 end

    assert (Functorial.bind(f) |> Functorial.bind(g)).(Functorial.lift(5)) == {:ok, 13}
  end

  test "~> functions as bind" do
    f = fn x -> {:ok, x + 2} end
    g = fn y -> y * 3 end
    bound_f_of_g = f ~> g

    assert bound_f_of_g.(2) == {:ok, 12}
  end
end
