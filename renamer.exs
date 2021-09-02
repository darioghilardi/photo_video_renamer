# Rename pictures and videos to their creation date according to the EXIF tags.
#
# Usage:
#   > elixir renamer.exs path_with_pics
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

defmodule Runner do
  @video_files ~w(.mov .MOV)

  def run(filepath) do
    filepath
    |> IO.inspect(label: "\n")
    |> identify_format()
    |> read_date()
    |> parse_date()
    |> stringify_date()
    |> IO.inspect()
  end

  defp identify_format(filepath) do
    if Enum.member?(@video_files, Path.extname(filepath)) do
      {:video, filepath}
    else
      {:image, filepath}
    end
  end

  defp read_date({:video, filepath}) do
    {date, _status} = System.cmd("exiftool", ["-T", "-CreationDate", "-ee", filepath])

    {:with_timezone, date}
  end

  defp read_date({:image, filepath}) do
    case read_date_time_original(filepath) do
      "-\n" ->
        IO.inspect("no original date, looking for datetime")

        date =
          filepath
          |> read_date_time()

        {:with_timezone, date}

      date ->
        {:no_timezone, date}
    end
  end

  defp read_date_time_original(filepath) do
    {date, _status} = System.cmd("exiftool", ["-T", "-DateTimeOriginal", "-ee", filepath])
    date
  end

  defp read_date_time(filepath) do
    {date, _status} = System.cmd("exiftool", ["-T", "-FileModifyDate", "-ee", filepath])
    date
  end

  defp parse_date({:no_timezone, date}) do
    date
    |> String.trim("\n")
    |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime)
  end

  defp parse_date({:with_timezone, date}) do
    date
    |> String.trim("\n")
    |> String.split("+")
    |> hd()
    |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime)
  end

  defp stringify_date(date) do
    Timex.format!(date, "%Y%m%d_%H%M%S", :strftime)
  end
end

# return all the dates
dates =
  System.argv()
  |> hd()
  |> File.ls!()
  |> Enum.map(&Runner.run(path <> &1))

# list the duplicates
duplicates = Enum.uniq(dates -- Enum.uniq(dates))
IO.inspect(duplicates, label: "duplicates")
