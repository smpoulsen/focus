defmodule FocusTest do
  use ExUnit.Case
  import Focus
  doctest Focus

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

  test "Composing set doesn't add new keys", %{test_structure: test_structure} do
    lenses = Lens.make_lenses(test_structure)

    updated = lenses.address
    ~> lenses.name
    ~> lenses.name
    |> Focus.set(test_structure, "Test")

    refute Map.has_key?(test_structure.address, :name)
    refute Map.has_key?(updated.address, :name)
    assert updated == test_structure
  end
end
