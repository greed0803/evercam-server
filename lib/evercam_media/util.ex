defmodule EvercamMedia.Util do
  require Logger

  @doc ~S"""
  Checks if a given binary data is a valid jpeg or not

  ## Examples

      iex> EvercamMedia.Util.is_jpeg("string")
      false

      iex> EvercamMedia.Util.is_jpeg("binaryimage")
      true
  """
  def is_jpeg(data) do
    case data do
      <<0xFF,0xD8, _data :: binary>> -> true
      _ -> false
    end
  end

  def is_jpeg_strict(camera_exid, timestamp, data) do
    try do
      size_without_magic = byte_size(data) - 5
      <<0xFF, 0xD8, _data :: binary-size(size_without_magic), ending :: binary-size(3)>> = data
      Logger.info "[#{camera_exid}] [jpeg_check] [#{inspect ending}] [#{timestamp}]"
      true
    rescue
      _ -> false
    end
  end

  def decode_request_token(token) do
    {_, encrypted_message} = Base.url_decode64(token)
    message = :crypto.block_decrypt(
      :aes_cbc256,
      System.get_env["SNAP_KEY"],
      System.get_env["SNAP_IV"],
      encrypted_message
    )
    String.split(message, "|")
  end

  def broadcast_snapshot(camera_exid, image, timestamp) do
    EvercamMedia.Endpoint.broadcast(
      "cameras:#{camera_exid}",
      "snapshot-taken",
      %{image: Base.encode64(image), timestamp: timestamp}
    )
  end

  def s3_file_url(file_name) do
    configure_erlcloud
    "/" <> name = file_name
    name   = String.to_char_list(name)
    bucket = System.get_env("AWS_BUCKET") |> String.to_char_list
    {_expires, host, uri} = :erlcloud_s3.make_link(100000000, bucket, name)
    "#{to_string(host)}#{to_string(uri)}"
  end

  def error_handler(error) do
    Logger.error inspect(error)
    Logger.error Exception.format_stacktrace System.stacktrace
  end

  defp configure_erlcloud do
    :erlcloud_s3.configure(
      to_char_list(System.get_env["AWS_ACCESS_KEY"]),
      to_char_list(System.get_env["AWS_SECRET_KEY"])
    )
  end

  def format_snapshot_id(camera_id, snapshot_timestamp) do
    "#{camera_id}_#{format_snapshot_timestamp(snapshot_timestamp)}"
  end

  def format_snapshot_timestamp(<<snapshot_timestamp::bytes-size(14)>>) do
    "#{snapshot_timestamp}000"
  end

  def format_snapshot_timestamp(<<snapshot_timestamp::bytes-size(17)>>) do
    snapshot_timestamp
  end
end
