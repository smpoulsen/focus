defprotocol Lensable do
  @fallback_to_any true

  @doc "A function to get a value out of a data structure"
  def getter(structure, view)

  @doc "A function to set a value out of a data structure"
  def setter(structure, view, func)
end

defimpl Lensable, for: Map do
  def getter(s, x), do: Access.get(s, x, {:error, {:lens, :bad_path}})
  def setter({:error, {:lens, :bad_path}} = e), do: e
  def setter(s, x, f) do
    if Map.has_key?(s, x) do
      Map.put(s, x, f)
    else
      s
    end
  end
end

defimpl Lensable, for: Tuple do
  def getter(s, x) when is_tuple(s) and is_integer(x) do
    elem(s, x)
  end
  def getter(_, _), do: {:error, {:lens, :bad_path}}
  def setter(s, x, f) do
    s
    |> Tuple.delete_at(x)
    |> Tuple.insert_at(x, f)
  end
end

defimpl Lensable, for: List do
  def getter(s, x) do
    if Keyword.keyword?(s) && !Enum.empty?(s) do
      Keyword.get(s, x)
    else
      if is_number(x) && !Enum.empty?(s) do
        get_in(s, [Access.at(x)])
      else
        {:error, {:lens, :bad_path}}
      end
    end
  end

  def setter([] = s, x, f), do: List.replace_at(s, x, f)
  def setter(s, x, f) do
    if Keyword.keyword?(s) do
      Keyword.put(s, x, f)
    else
      List.replace_at(s, x, f)
    end
  end
end

defimpl Lensable, for: Any do
  def getter(_, _), do: {:error, {:lens, :bad_data_structure}}
  def setter(_s, _x, _f), do: {:error, {:lens, :bad_data_structure}}
end
