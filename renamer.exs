# Rename pictures and videos to their creation date according to the EXIF tags.
#
# Usage:
#   > elixir renamer.exs path_with_pics/
#
# Notes:
# Command for MOV files:
#   > exiftool -CreationDate -ee filepath
# Command for JPEG files:
#   > exiftool -DateTimeOriginal -ee filepath
# Variant using exiv2:
#   > {out, _status} = System.cmd("exiv2", ["-g", "Exif.Image.DateTime", "-Pv", filepath])

Mix.install([
  {:timex, "~> 3.0"}
])

defmodule Video do
  def process(filepath) do
    IO.puts("Processing videos")

    filepath
    |> read_video_date()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "\t"))
    # Reject videos without date, will need to rename them manually
    |> Enum.reject(fn i -> Enum.count(i) == 1 end)
    |> Enum.map(fn [date, filename] -> %{date: date, filename: filename} end)
    |> Enum.map(&parse_date(:with_timezone, &1))
    |> Enum.map(&stringify_date(&1))
    |> IO.inspect(limit: :infinity)
  end

  defp read_video_date(filepath) do
    {output, _status} =
      System.cmd("/bin/sh", [
        "-c",
        "exiftool -T -CreationDate -FileName -ee #{filepath}*{.mov,.MOV}"
      ])

    output
  end

  defp parse_date(:with_timezone, %{date: date, filename: filename}) do
    %{
      date:
        date
        |> String.trim("\n")
        |> String.split("+")
        |> hd()
        |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime),
      filename: filename
    }
  end

  defp stringify_date(%{date: date} = file) do
    file |> Map.put(:date, Timex.format!(date, "%Y%m%d_%H%M%S", :strftime))
  end
end

defmodule Image do
  def process(filepath) do
    IO.puts("Processing images")

    filepath
    |> read_image_original_date()
    |> String.split("\n")
    |> IO.inspect(limit: :infinity)

    # |> Enum.map(&String.split(&1, "\t"))
    # # Reject videos without date, will need to rename them manually
    # |> Enum.reject(fn i -> Enum.count(i) == 1 end)
    # |> Enum.map(fn [date, filename] -> %{date: date, filename: filename} end)
    # |> Enum.map(&parse_date(:with_timezone, &1))
    # |> IO.inspect(limit: :infinity)
    # |> Enum.map(&stringify_date(&1))
    # |> IO.inspect(limit: :infinity)
  end

  defp read_image_original_date(filepath) do
    {output, _status} =
      System.cmd("/bin/sh", [
        "-c",
        "exiftool -T -DateTimeOriginal -FileName -ee #{filepath}*{.jpg,.JPG,.jpeg,.JPEG,.heic,.HEIC}"
      ])

    output
  end

  defp parse_date(:with_timezone, %{date: date, filename: filename}) do
    %{
      date:
        date
        |> String.trim("\n")
        |> String.split("+")
        |> hd()
        |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime),
      filename: filename
    }
  end

  # defp read_date({:image, filepath}) do
  #   case read_date_time_original(filepath) do
  #     "-\n" ->
  #       IO.inspect("no original date, looking for datetime")

  #       date =
  #         filepath
  #         |> read_date_time()

  #       {:with_timezone, date}

  #     date ->
  #       {:no_timezone, date}
  #   end
  # end

  defp read_date_time(filepath) do
    {date, _status} = System.cmd("exiftool", ["-T", "-FileModifyDate", "-ee", filepath])
    date
  end

  defp parse_date({:no_timezone, date}) do
    date
    |> String.trim("\n")
    |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime)
  end
end

path = System.argv() |> hd()

# return all the dates
# videos = Video.process(path)
images = Image.process(path)

# |> File.ls!()
# |> Enum.map(&Runner.run(path <> &1))

# list the duplicates
# duplicates = Enum.uniq(dates -- Enum.uniq(dates))
# IO.inspect(duplicates, label: "duplicates")
