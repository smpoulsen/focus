defmodule Focus.Types do
  @moduledoc """
  Shared elements for the Focus modules.
  """
  @type product     :: map | struct | tuple
  @type sum         :: list
  @type traversable :: product | sum
  @type maybe       :: {:ok, any} | {:error, any}
  @type optic       :: Focus.Lens.t
end
