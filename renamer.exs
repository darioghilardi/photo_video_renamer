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
    |> rename(filepath)
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
    {output, _status} =
      System.cmd("exiftool", ["-T", "-CreationDate", "-FileName", "-ee", filepath])

    list =
      output
      |> String.trim("\n")
      |> String.split("\t")
      |> (fn [date, filename] -> %{date: date, filename: filename} end).()

    {:with_timezone, list}
  end

  defp read_date({:image, filepath}) do
    case read_date_time_original(filepath) do
      %{date: "-", filename: _} ->
        IO.inspect("no original date, looking for datetime")

        date =
          filepath
          |> read_date_time()

        {:with_timezone, date}

      file ->
        {:no_timezone, file}
    end
  end

  defp read_date_time_original(filepath) do
    {output, _status} =
      System.cmd("exiftool", ["-T", "-DateTimeOriginal", "-Filename", "-ee", filepath])

    output
    |> String.trim("\n")
    |> String.split("\t")
    |> IO.inspect()
    |> (fn [date, filename] -> %{date: date, filename: filename} end).()
  end

  defp read_date_time(filepath) do
    {output, _status} =
      System.cmd("exiftool", ["-T", "-FileModifyDate", "-Filename", "-ee", filepath])

    output
    |> String.trim("\n")
    |> String.split("\t")
    |> (fn [date, filename] -> %{date: date, filename: filename} end).()
  end

  defp parse_date({:no_timezone, %{date: date, filename: filename}}) do
    %{date: date |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime), filename: filename}
  end

  defp parse_date({:with_timezone, %{date: date, filename: filename}}) do
    %{
      date: date |> String.split("+") |> hd() |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime),
      filename: filename
    }
  end

  defp stringify_date(%{date: date} = file) do
    file |> Map.put(:date, Timex.format!(date, "%Y%m%d_%H%M%S", :strftime))
  end

  # To rename I need the filename
  defp rename(%{date: date, filename: filename}, filepath) do
    ext = Path.extname(filename)

    case File.exists?(filepath <> date <> ext) do
      # finish the recursion here to handle duplicated filenames
      true -> rename(%{date: date})
    end
  end
end

# return all the dates
path = System.argv() |> hd()

dates =
  path
  |> File.ls!()
  |> Enum.map(&Runner.run(path <> &1))

# list the duplicates
duplicates = Enum.uniq(dates -- Enum.uniq(dates))
IO.inspect(duplicates, label: "duplicates")
