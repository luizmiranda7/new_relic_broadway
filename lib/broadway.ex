defmodule NewRelicBroadway.Telemetry.Broadway do
  @moduledoc """
  Provides `Broadway` instrumentation via `telemetry`.

  Broadway pipelines are auto-discovered and instrumented.

  We automatically gather:

  * Transaction metrics and events
  * Transaction Traces

  ----

  To prevent reporting an individual transaction:

  ```elixir
  NewRelic.ignore_transaction()
  ```

  ----

  Inside a Transaction, the agent will track work across processes that are spawned and linked.
  You can signal to the agent not to track work done inside a spawned process, which will
  exclude it from the current Transaction.

  To exclude a process from the Transaction:

  ```elixir
  Task.async(fn ->
    NewRelic.exclude_from_transaction()
    Work.wont_be_tracked()
  end)
  ```
  """

  use GenServer

  alias NewRelic.Transaction

  @doc false
  def start_link(_) do
    config = %{
      handler_id: {:new_relic, :broadway}
    }

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @broadway_start [:broadway, :processor, :message, :start]
  @broadway_stop [:broadway, :processor, :message, :stop]
  @broadway_exception [:broadway, :processor, :message, :exception]

  @broadway_events [
    @broadway_start,
    @broadway_stop,
    @broadway_exception
  ]

  @doc false
  def init(config) do
    :telemetry.attach_many(
      config.handler_id,
      @broadway_events,
      &__MODULE__.handle_event/4,
      config
    )

    Process.flag(:trap_exit, true)
    {:ok, config}
  end

  @doc false
  def terminate(_reason, %{handler_id: handler_id}) do
    :telemetry.detach(handler_id)
  end

  @doc false
  def handle_event(
        @broadway_start,
        %{system_time: system_time},
        meta,
        _config
      ) do
    Transaction.Reporter.start_transaction(:other)

    add_start_attrs(meta, system_time)
  end

  def handle_event(
        @broadway_stop,
        %{duration: duration} = _meas,
        _meta,
        _config
      ) do
    add_stop_attrs(duration)

    Transaction.Reporter.stop_transaction(:other)
  end

  def handle_event(
        @broadway_exception,
        %{duration: duration} = _meas,
        %{kind: kind} = meta,
        _config
      ) do
    add_stop_attrs(duration)
    {reason, stack} = reason_and_stack(meta)

    Transaction.Reporter.fail(%{kind: kind, reason: reason, stack: stack})
    Transaction.Reporter.stop_transaction(:other)
  end

  def handle_event(_event, _measurements, _meta, _config) do
    :ignore
  end

  defp add_start_attrs(meta, system_time) do
    name = "Broadway/#{meta.topology_name}/perform"

    [
      pid: inspect(self()),
      system_time: system_time,
      index: meta.index,
      name: name,
      other_transaction_name: name,
      topology_name: meta.topology_name,
      processor_key: meta.processor_key
    ]
    |> NewRelic.add_attributes()
  end

  @kb 1024
  defp add_stop_attrs(duration) do
    info = Process.info(self(), [:memory, :reductions])

    [
      duration: duration,
      memory_kb: info[:memory] / @kb,
      reductions: info[:reductions]
    ]
    |> NewRelic.add_attributes()
  end

  defp reason_and_stack(%{reason: %{__exception__: true} = reason, stacktrace: stack}) do
    {reason, stack}
  end

  defp reason_and_stack(%{reason: {{reason, stack}, _init_call}}) do
    {reason, stack}
  end

  defp reason_and_stack(%{reason: {reason, _init_call}}) do
    {reason, []}
  end

  defp reason_and_stack(unexpected_exception) do
    NewRelic.log(:debug, "unexpected_exception: #{inspect(unexpected_exception)}")
    {:unexpected_exception, []}
  end
end
