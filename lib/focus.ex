defprotocol Focusable do
  @doc "View the data that an optic focuses on."
  def view(optic, structure)

  @doc "Modify the data that an optic focuses on."
  def over(optic, structure, f)

  @doc "Set the data that an optic focuses on."
  def set(optic, structure, value)

  @doc "Create a new optic by combining two others."
  def compose(optic, optic)

  @doc "Infix of Focus.compose/2"
  def (optic) ~> (optic)
end

defmodule Focus do
  alias Focus.Types

  @spec view(Types.optic, Types.traversable) :: any | nil
  def view(optic, structure) do
    Focusable.view(optic, structure)
  end

  @spec over(Types.optic, Types.traversable, ((any) -> any)) :: Types.traversable
  def over(optic, structure, f) do
    Focusable.over(optic, structure, f)
  end

  def set(optic, structure, v) do
    Focusable.set(optic, structure, v)
  end
end
