defmodule EvercamMedia.EvercamBot.TelegramSupervisor do
  @moduledoc """
  Provides function to manage Telegram_bot workers
  """

  use Supervisor
  require Logger
  @bot_name Application.get_env(:evercam_media, :bot_name)
  #alias EvercamMedia.Evercam_bot.Matcher
  #alias EvercamMedia.Evercam_bot.Poller

  #@name EvercamMedia.Evercam_bot.TelegramSupervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__ )
  end

  def init(:ok) do
    Task.start_link(&start_matcher/0)
    children = [
      worker(EvercamMedia.EvercamBot.Poller, [], restart: :permanent),
      worker(EvercamMedia.Evercam_bot.Matcher, [], restart: :permanent)
    ]
    supervise(children, strategy: :simple_one_for_one, max_restarts: 1_000_000)
  end

  @doc """
  Start Telegram_bot worker
  """
  def start_matcher() do
    unless String.valid?(@bot_name) do
      IO.warn """

      Env not found Application.get_env(:app, :bot_name)
      This will give issues when generating commands
      """
    end

    if @bot_name == "testevercam_bot" do
      IO.warn "An empty bot_name env will make '/anycommand@' valid"
      Supervisor.start_child(__MODULE__, [])
    end

  end
end
