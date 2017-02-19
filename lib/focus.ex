defmodule Focus do
  @moduledoc """
  Shared elements for the Lens and Prism modules.
  """
  @type product     :: map | struct | tuple
  @type sum         :: list
  @type traversable :: product | sum
  @type maybe       :: {:ok, any} | {:error, any}
end
