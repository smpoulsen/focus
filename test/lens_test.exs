defmodule LensTest do
  use ExUnit.Case
  use Quixir
  import Focus

  defmodule PersonExample do
    @moduledoc "Used in the deflenses doctest example"
    import Lens
    deflenses name: nil, age: nil
  end

  doctest Lens
  doctest Focusable.Lens

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
      assert Focus.view(lens, Focus.set(lens, structure, new_name)) == new_name
    end
  end

  test "Lens law: Get/Put - setting a value that is retrieved is doing nothing" do
    ptest structure: map(like: %{name: string()}) do
      lens = Lens.make_lens(:name)
      assert Focus.set(lens, structure, Focus.view(lens, structure)) == structure
    end
  end

  test "Lens law: Put/Put - last set value wins" do
    ptest structure: map(like: %{name: string()}), name1: string(), name2: string() do
      lens = Lens.make_lens(:name)
      assert Focus.view(lens, Focus.set(lens, Focus.set(lens, structure, name1), name2)) == name2
    end
  end

  test "get data from a map", %{test_structure: test_structure} do
    name_lens = Lens.make_lens(:name)
    assert Focus.view(name_lens, test_structure) == "Homer"
  end

  test "set data in a map", %{test_structure: test_structure} do
    name_lens = Lens.make_lens(:name)
    assert Focus.set(name_lens, test_structure, "Bart") == %{test_structure | name: "Bart"}
  end

  test "manipulate data in a map", %{test_structure: test_structure} do
    name_lens = Lens.make_lens(:name)
    assert Focus.over(name_lens, test_structure, &String.reverse/1) ==
      %{test_structure | name: "remoH"}
  end

  test "view a key with a value of nil in a map" do
    s = %{name: nil}
    assert Focus.view(Lens.make_lens(:name), s) == nil
  end

  test "update a key with a value of nil in a map" do
    s = %{name: nil}
    assert Focus.set(Lens.make_lens(:name), s, "Bart") == %{name: "Bart"}
  end

  test "get data from a tuple", %{test_structure: test_structure} do
    tuple_lens = Lens.make_lens(:tuple)
    first_elem = Lens.make_lens(0)
    assert (tuple_lens ~> first_elem |> Focus.view(test_structure)) == :a
  end

  test "set data in a tuple", %{test_structure: test_structure} do
    tuple_lens = Lens.make_lens(:tuple)
    first_elem = Lens.make_lens(0)
    assert (tuple_lens ~> first_elem |> Focus.set(test_structure, "Pineapple")) ==
      %{test_structure | tuple: {"Pineapple", :b, :c}}
  end

  test "manipulate data in a tuple", %{test_structure: test_structure} do
    tuple_lens = Lens.make_lens(:tuple)
    first_elem = Lens.make_lens(0)
    assert (tuple_lens ~> first_elem |> Focus.over(test_structure, &Atom.to_string/1)) ==
      %{test_structure | tuple: {"a", :b, :c}}
  end

  test "get data from a deep map", %{test_structure: test_structure} do
    address = Lens.make_lens(:address)
    locale = Lens.make_lens(:locale)
    street = Lens.make_lens(:street)
    assert (address ~> locale ~> street |> Focus.view(test_structure)) == "Fake St."
  end

  test "set data in a deep map", %{test_structure: test_structure} do
    address = Lens.make_lens(:address)
    locale = Lens.make_lens(:locale)
    street = Lens.make_lens(:street)
    assert (address ~> locale ~> street |> Focus.set(test_structure, "Evergreen Terrace")) ==
      %{test_structure | address: %{
           test_structure.address | locale: %{
             test_structure.address.locale | street: "Evergreen Terrace"}}}
  end

  test "manipulate data in a deep map", %{test_structure: test_structure} do
    address = Lens.make_lens(:address)
    locale = Lens.make_lens(:locale)
    street = Lens.make_lens(:street)
    assert (address ~> locale ~> street |> Focus.over(test_structure, &String.upcase/1)) ==
      %{test_structure | address: %{
           test_structure.address | locale: %{
             test_structure.address.locale | street: "FAKE ST."}}}
  end

  test "get data from a list", %{test_structure: test_structure} do
    list_lens = Lens.make_lens(:list)
    second_elem = Lens.idx(1)
    assert (list_lens ~> second_elem |> Focus.view(test_structure)) == 4
  end

  test "set data in a list", %{test_structure: test_structure} do
    list_lens = Lens.make_lens(:list)
    second_elem = Lens.idx(1)
    assert (list_lens ~> second_elem |> Focus.set(test_structure, "Banana")) ==
      %{test_structure | list: [2, "Banana", 8, 16, 32]}
  end

  test "manipulate data in a list", %{test_structure: test_structure} do
    list_lens = Lens.make_lens(:list)
    second_elem = Lens.idx(1)
    assert (list_lens ~> second_elem |> Focus.over(test_structure, fn x -> x * x * x end)) ==
      %{test_structure | list: [2, 64, 8, 16, 32]}
  end

  test "safe_view returns an error when composing into a non-existing path" do
    bad_path = %{list: []}
    good_path = %{list: [%{value: :hello}]}

    l = Lens.make_lens(:list)
    i = Lens.idx(0)
    v = Lens.make_lens(:value)

    assert Lens.safe_view(l ~> i ~> v, bad_path) == {:error, {:lens, :bad_data_structure}}
    assert Lens.safe_view(l ~> l ~> v, bad_path) == {:error, {:lens, :bad_path}}
    assert Lens.safe_view(l ~> i ~> v, good_path) == {:ok, :hello}
  end
end
