defmodule EvercamMedia.EvercamBot.Matcher do
  use GenStage
  alias EvercamMedia.EvercamBot.Commands

  # Server

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, 0}
  end

  def handle_cast(message, state) do
    Commands.match_message(message)

    {:noreply, [], state}
  end

  # Client

  def match(message) do
    GenStage.cast(__MODULE__, message)
  end
end
