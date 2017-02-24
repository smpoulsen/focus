defmodule PrismTest do
  use ExUnit.Case
  use Quixir
  import Focus
  doctest Prism
  doctest Focusable.Prism

  setup do
    test_structure = %{
      name: "Homer",
      address: %{
        locale: %{
          number: 123,
          street: "Fake St.",
        },
        city: "Springfield",
      },
      list: [2, 4, 8, 16, 32],
      tuple: {:a, :b, :c},
      deep_list: %{
        values: [5, 10, 15]
      }
    }

    {:ok, test_structure: test_structure}
  end

  test "get data from a list", %{test_structure: test_structure} do
    list_prism = Lens.make_lens(:list)
    second_elem = Prism.make_prism(1)
    assert (list_prism ~> second_elem |> Focus.view(test_structure)) == 4
  end

  test "set data in a list", %{test_structure: test_structure} do
    list_prism = Lens.make_lens(:list)
    second_elem = Prism.make_prism(1)
    assert (list_prism ~> second_elem |> Focus.set(test_structure, "Banana")) ==
      %{test_structure | list: [2, "Banana", 8, 16, 32]}
  end

  test "manipulate data in a list", %{test_structure: test_structure} do
    list_prism = Lens.make_lens(:list)
    second_elem = Prism.make_prism(1)
    assert (list_prism ~> second_elem |> Focus.over(test_structure, fn x -> x * x * x end)) ==
      %{test_structure | list: [2, 64, 8, 16, 32]}
  end

end
