defmodule Focus.LensTest do
  use ExUnit.Case
  use Quixir
  import Focus.Lens
  alias Focus.Lens
  doctest Focus.Lens

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

  test "Lens law: Put/Get - get a value that is set" do
    ptest structure: map(like: %{name: string()}), new_name: string() do
      lens = Lens.make_lens(:name)
      assert Lens.view(lens, Lens.set(lens, structure, new_name)) == new_name
    end
  end

  test "Lens law: Get/Put - setting a value that is retrieved is doing nothing" do
    ptest structure: map(like: %{name: string()}) do
      lens = Lens.make_lens(:name)
      assert Lens.set(lens, structure, Lens.view(lens, structure)) == structure
    end
  end

  test "Lens law: Put/Put - last set value wins" do
    ptest structure: map(like: %{name: string()}), name1: string(), name2: string() do
      lens = Lens.make_lens(:name)
      assert Lens.view(lens, Lens.set(lens, Lens.set(lens, structure, name1), name2)) == name2
    end
  end

  test "get data from a map", %{test_structure: test_structure} do
    name_lens = Lens.make_lens(:name)
    assert Lens.view(name_lens, test_structure) == "Homer"
  end

  test "set data in a map", %{test_structure: test_structure} do
    name_lens = Lens.make_lens(:name)
    assert Lens.set(name_lens, test_structure, "Bart") == %{test_structure | name: "Bart"}
  end

  test "manipulate data in a map", %{test_structure: test_structure} do
    name_lens = Lens.make_lens(:name)
    assert Lens.over(name_lens, test_structure, &String.reverse/1) ==
      %{test_structure | name: "remoH"}
  end

  test "get data from a tuple", %{test_structure: test_structure} do
    tuple_lens = Lens.make_lens(:tuple)
    first_elem = Lens.make_lens(0)
    assert (tuple_lens ~> first_elem |> Lens.view(test_structure)) == :a
  end

  test "set data in a tuple", %{test_structure: test_structure} do
    tuple_lens = Lens.make_lens(:tuple)
    first_elem = Lens.make_lens(0)
    assert (tuple_lens ~> first_elem |> Lens.set(test_structure, "Pineapple")) ==
      %{test_structure | tuple: {"Pineapple", :b, :c}}
  end

  test "manipulate data in a tuple", %{test_structure: test_structure} do
    tuple_lens = Lens.make_lens(:tuple)
    first_elem = Lens.make_lens(0)
    assert (tuple_lens ~> first_elem |> Lens.over(test_structure, &Atom.to_string/1)) ==
      %{test_structure | tuple: {"a", :b, :c}}
  end

  test "get data from a deep map", %{test_structure: test_structure} do
    address = Lens.make_lens(:address)
    locale = Lens.make_lens(:locale)
    street = Lens.make_lens(:street)
    assert (address ~> locale ~> street |> Lens.view(test_structure)) == "Fake St."
  end

  test "set data in a deep map", %{test_structure: test_structure} do
    address = Lens.make_lens(:address)
    locale = Lens.make_lens(:locale)
    street = Lens.make_lens(:street)
    assert (address ~> locale ~> street |> Lens.set(test_structure, "Evergreen Terrace")) ==
      %{test_structure | address: %{
           test_structure.address | locale: %{
             test_structure.address.locale | street: "Evergreen Terrace"}}}
  end

  test "manipulate data in a deep map", %{test_structure: test_structure} do
    address = Lens.make_lens(:address)
    locale = Lens.make_lens(:locale)
    street = Lens.make_lens(:street)
    assert (address ~> locale ~> street |> Lens.over(test_structure, &String.upcase/1)) ==
      %{test_structure | address: %{
           test_structure.address | locale: %{
             test_structure.address.locale | street: "FAKE ST."}}}
  end

  test "get data from a list", %{test_structure: test_structure} do
    list_lens = Lens.make_lens(:list)
    second_elem = Lens.make_lens(1)
    assert (list_lens ~> second_elem |> Lens.view(test_structure)) == 4
  end

  test "set data in a list", %{test_structure: test_structure} do
    list_lens = Lens.make_lens(:list)
    second_elem = Lens.make_lens(1)
    assert (list_lens ~> second_elem |> Lens.set(test_structure, "Banana")) ==
      %{test_structure | list: [2, "Banana", 8, 16, 32]}
  end

  test "manipulate data in a list", %{test_structure: test_structure} do
    list_lens = Lens.make_lens(:list)
    second_elem = Lens.make_lens(1)
    assert (list_lens ~> second_elem |> Lens.over(test_structure, fn x -> x * x * x end)) ==
      %{test_structure | list: [2, 64, 8, 16, 32]}
  end
end
