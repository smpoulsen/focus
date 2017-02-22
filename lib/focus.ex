defprotocol Focus do
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
