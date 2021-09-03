# Rename pictures and videos to their creation date according to the EXIF tags.
#
# Usage:
#   > elixir renamer.exs path_with_pics/
#
# Notes:
# Command for MOV files:
#   > exiftool -CreationDate -ee filepath
#
# Command for JPEG files:
#   > exiftool -DateTimeOriginal -ee filepath
#
# Fallback for JPEG files:
#   > exiftool -FileModifyDate -ee filepath
#
# Variant using exiv2:
#   > {out, _status} = System.cmd("exiv2", ["-g", "Exif.Image.DateTime", "-Pv", filepath])

Mix.install([
  {:timex, "~> 3.0"}
])

defmodule Reader do
  @video_ext ~w(.mov .MOV)
  @image_ext ~w(.jpg .JPG .jpeg .JPEG .heic .HEIC)

  def process(filepath) do
    filepath
    |> read_exif()
    |> parse_exif()
    |> Enum.map(&select_date_field/1)
    |> Enum.map(&stringify_date/1)
    |> IO.inspect()
    |> rename_duplicates(filepath)

    # |> String.split("\n")
    # |> Enum.map(&String.split(&1, "\t"))
    # # Reject videos without date, will need to rename them manually
    # |> Enum.reject(fn i -> Enum.count(i) == 1 end)
    # |> Enum.map(fn [date, filename] -> %{date: date, filename: filename} end)
    # |> Enum.map(&parse_date(:with_timezone, &1))
    # |> Enum.map(&stringify_date(&1))
    # |> IO.inspect(limit: :infinity)
  end

  defp read_exif(filepath) do
    IO.puts("Reading Exif Tags")

    {output, _status} =
      System.cmd("exiftool", [
        "-T",
        "-CreationDate",
        "-DateTimeOriginal",
        "-FileModifyDate",
        "-FileName",
        "-ee",
        filepath
      ])

    output
  end

  defp parse_exif(output) do
    IO.puts("Parsing Exif Tags")

    output
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "\t"))
    # Reject empty results
    |> Enum.reject(fn i -> Enum.count(i) == 1 end)
    |> Enum.map(fn [creation_date, date_time_original, modify_date, filename] ->
      %{
        creation_date: parse_date_with_tz(creation_date),
        date_time_original: parse_date(date_time_original),
        modify_date: parse_date_with_tz(modify_date),
        filename: filename
      }
    end)
  end

  defp parse_date("-"), do: "-"
  defp parse_date(date), do: date |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime)

  defp parse_date_with_tz("-"), do: "-"

  defp parse_date_with_tz(date) do
    date
    |> String.split("+")
    |> hd()
    |> Timex.parse!("%Y:%m:%d %H:%M:%S", :strftime)
  end

  def select_date_field(%{
        creation_date: creation_date,
        date_time_original: date_time_original,
        modify_date: modify_date,
        filename: filename
      }) do
    ext = Path.extname(filename)

    cond do
      Enum.member?(@video_ext, ext) ->
        %{filename: filename, date: creation_date}

      Enum.member?(@video_ext, ext) ->
        %{filename: filename, date: creation_date}

      Enum.member?(@image_ext, ext) and Timex.is_valid?(date_time_original) ->
        %{filename: filename, date: date_time_original}

      Enum.member?(@image_ext, ext) and !Timex.is_valid?(date_time_original) ->
        %{filename: filename, date: modify_date}
    end
  end

  defp stringify_date(%{date: date} = file) do
    file |> Map.put(:date, Timex.format!(date, "%Y%m%d_%H%M%S", :strftime))
  end

  defp rename_duplicates(list, filepath) do
    list
    |> Enum.map(&rename_file(&1, filepath))
  end

  def rename_file(%{date: date, filename: filename} = file, filepath, suffix \\ 0) do
    ext = Path.extname(filename)
    old_name = filepath <> filename
    new_name = generate_new_name(filepath, date, ext, suffix)

    case(File.exists?(new_name)) do
      true ->
        rename_file(file, filepath, suffix + 1)

      false ->
        File.rename(old_name, new_name)
        IO.puts("File #{old_name} renamed to #{new_name}")
    end
  end

  defp generate_new_name(filepath, date, ext, 0), do: filepath <> date <> ext

  defp generate_new_name(filepath, date, ext, suffix),
    do: filepath <> date <> "_" <> Integer.to_string(suffix) <> ext
end

path = System.argv() |> hd()
Reader.process(path)
