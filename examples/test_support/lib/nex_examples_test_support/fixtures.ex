defmodule NexExamplesTestSupport.Fixtures do
  @fixtures_root Path.expand("../../fixtures", __DIR__)

  def root, do: @fixtures_root

  def path(filename) do
    Path.join(@fixtures_root, filename)
  end
end
