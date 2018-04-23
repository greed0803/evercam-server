defmodule EvercamMedia.SnapshotExtractor.ExtractorSupervisor do

  use Supervisor
  require Logger
  alias EvercamMedia.SnapshotExtractor.Extractor

  @root_dir Application.get_env(:evercam_media, :storage_dir)

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Task.start_link(&initiate_workers/0)
    children = [worker(Extractor, [], restart: :permanent)]
    supervise(children, strategy: :simple_one_for_one, max_restarts: 1_000_000)
  end

  def initiate_workers do
    Logger.info "Initiate workers for extractor."
    in_processing_extractors = SnapshotExtractor.by_status(11)

    cameras =
      in_processing_extractors
      |> Enum.map(fn(x) -> x.camera_id end)
      |> Enum.uniq

    extractor_by_camera_id =
      in_processing_extractors
      |> Enum.group_by(&(&1.camera_id))

    cameras
    |> Enum.each(fn(camera_id) ->
      extractor_by_camera_id[camera_id]
      |> start_extractor_process()
    end)
  end

  def start_extractor_process(extractor_list) do
    extractor_list
    |> Enum.each(fn(extractor) ->
      start_extraction(extractor)
    end)
  end

  def start_extraction(nil), do: :noop
  def start_extraction(extractor) do
    Logger.debug "Ressuming extraction for #{extractor.camera.exid}"
    Process.whereis(:snapshot_extractor)
    |> get_process_pid
    |> GenStage.cast({:snapshot_extractor, get_config(extractor)})
  end

  defp get_process_pid(nil) do
    {:ok, pid} = GenStage.start_link(EvercamMedia.SnapshotExtractor.Extractor, {}, name: :snapshot_extractor)
    pid
  end
  defp get_process_pid(pid), do: pid

  def get_config(extractor) do
    camera = Camera.by_exid_with_associations(extractor.camera.exid)
    host = Camera.host(camera, "external")
    port = Camera.port(camera, "external", "rtsp")
    cam_username = Camera.username(camera)
    cam_password = Camera.password(camera)
    url = camera.vendor_model.h264_url
    channel = url |> String.split("/channels/") |> List.last |> String.split("/") |> List.first
    %{
      exid: camera.exid,
      id: extractor.id,
      timezone: Camera.get_timezone(camera),
      host: host,
      port: port,
      username: cam_username,
      password: cam_password,
      channel: channel,
      start_date: get_starting_date(extractor),
      end_date: parse_ecto_to_datetime(extractor.to_date),
      interval: extractor.interval,
      schedule: extractor.schedule,
      requester: extractor.requestor,
      create_mp4: serve_nil_value(extractor.create_mp4),
      jpegs_to_dropbox: serve_nil_value(extractor.jpegs_to_dropbox),
      inject_to_cr: serve_nil_value(extractor.inject_to_cr)
    }
  end

  defp serve_nil_value(nil), do: false
  defp serve_nil_value(val), do: val

  defp get_starting_date(extractor) do
    File.read!("#{@root_dir}/#{extractor.camera.exid}/extract/#{extractor.id}/CURRENT")
    |> Timex.parse!("%Y-%m-%d-%H-%M-%S", :strftime)
    |> Ecto.DateTime.cast!
    |> parse_ecto_to_datetime
  end

  defp parse_ecto_to_datetime(datetime) do
    datetime
    |> Ecto.DateTime.dump
    |> elem(1)
    |> Timex.DateTime.Helpers.construct("Etc/UTC")
  end
end
