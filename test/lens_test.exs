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
  test "lens law - get a value that is set" do
    ptest structure: map(like: %{name: string()}), new_name: string() do
      lens = Lens.makeLens(:name)
      assert Lens.view!(lens, Lens.set(lens, new_name, structure)) == new_name
    end
  end

  test "lens law - setting a value that is retrieved is doing nothing" do
    ptest structure: map(like: %{name: string()}) do
      lens = Lens.makeLens(:name)
      assert Lens.set(lens, Lens.view!(lens, structure), structure) == structure
    end
  end

  test "get data from a map", %{test_structure: test_structure} do
    nameLens = Lens.makeLens(:name)
    assert Lens.view!(nameLens, test_structure) == "Homer"
    assert Lens.view(nameLens, test_structure) == {:ok, "Homer"}
  end

  test "set data in a map", %{test_structure: test_structure} do
    nameLens = Lens.makeLens(:name)
    assert Lens.set(nameLens, "Bart", test_structure) == %{test_structure | name: "Bart"}
  end

  test "manipulate data in a map", %{test_structure: test_structure} do
    nameLens = Lens.makeLens(:name)
    assert Lens.over(nameLens, &String.reverse/1, test_structure) == %{test_structure | name: "remoH"}
  end

  test "get data from a list", %{test_structure: test_structure} do
    listLens = Lens.makeLens(:list)
    secondElem = Lens.makeLens(1)
    assert (listLens ~> secondElem |> Lens.view!(test_structure)) == 4
    assert (listLens ~> secondElem |> Lens.view(test_structure)) == {:ok, 4}
  end

  test "set data in a list", %{test_structure: test_structure} do
    listLens = Lens.makeLens(:list)
    secondElem = Lens.makeLens(1)
    assert (listLens ~> secondElem |> Lens.set("Banana", test_structure)) == %{test_structure | list: [2, "Banana", 8, 16, 32]}
  end

  test "manipulate data in a list", %{test_structure: test_structure} do
    listLens = Lens.makeLens(:list)
    secondElem = Lens.makeLens(1)
    assert (listLens ~> secondElem |> Lens.over(fn x -> x * x * x end, test_structure)) == %{test_structure | list: [2, 64, 8, 16, 32]}
  end

  test "get data from a tuple", %{test_structure: test_structure} do
    tupleLens = Lens.makeLens(:tuple)
    firstElem = Lens.makeLens(0)
    assert (tupleLens ~> firstElem |> Lens.view!(test_structure)) == :a
    assert (tupleLens ~> firstElem |> Lens.view(test_structure)) == {:ok, :a}
  end

  test "set data in a tuple", %{test_structure: test_structure} do
    tupleLens = Lens.makeLens(:tuple)
    firstElem = Lens.makeLens(0)
    assert (tupleLens ~> firstElem |> Lens.set("Pineapple", test_structure)) == %{test_structure | tuple: {"Pineapple", :b, :c}}
  end

  test "manipulate data in a tuple", %{test_structure: test_structure} do
    tupleLens = Lens.makeLens(:tuple)
    firstElem = Lens.makeLens(0)
    assert (tupleLens ~> firstElem |> Lens.over(&Atom.to_string/1, test_structure)) == %{test_structure | tuple: {"a", :b, :c}}
  end

  test "get data from a deep map", %{test_structure: test_structure} do
    address = Lens.makeLens(:address)
    locale = Lens.makeLens(:locale)
    street = Lens.makeLens(:street)
    assert (address ~> locale ~> street |> Lens.view!(test_structure)) == "Fake St."
    assert (address ~> locale ~> street |> Lens.view(test_structure)) == {:ok, "Fake St."}
  end

  test "set data in a deep map", %{test_structure: test_structure} do
    address = Lens.makeLens(:address)
    locale = Lens.makeLens(:locale)
    street = Lens.makeLens(:street)
    assert (address ~> locale ~> street |> Lens.set("Evergreen Terrace", test_structure)) ==
      %{test_structure | address: %{test_structure.address | locale: %{test_structure.address.locale | street: "Evergreen Terrace"}}}
  end

  test "manipulate data in a deep map", %{test_structure: test_structure} do
    address = Lens.makeLens(:address)
    locale = Lens.makeLens(:locale)
    street = Lens.makeLens(:street)
    assert (address ~> locale ~> street |> Lens.over(&String.upcase/1, test_structure)) ==
      %{test_structure | address: %{test_structure.address | locale: %{test_structure.address.locale | street: "FAKE ST."}}}
  end

end
