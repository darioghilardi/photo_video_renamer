Mix.install([
  {:timex, "~> 3.0"}
])

defmodule Renamer do
  def process(filepath) do
    filepath
    |> read_exif(from_file: false)
    |> parse_exif()
    |> write_exif_results()
    |> Enum.map(&select_date_field/1)
    |> Enum.map(&stringify_date/1)
    |> rename_duplicates(filepath)
  end

  defp read_exif(filepath, [from_file: from_file]) do
    if from_file do
      IO.puts("Reading Exif Tags from dumped exif_read.txt...")
      File.read!("exif_read.txt")
    else
    IO.puts("Reading Exif Tags from pictures folder...")
    {output, _status} =
      System.cmd("exiftool", [
        "-dateFormat",
        "%Y-%m-%d %H:%M:%S",
        "-T",
        "-CreationDate",
        "-DateTimeOriginal",
        "-FileModifyDate",
        "-FileName",
        "-ee",
        filepath
      ])
      File.write!("exif_read.txt", output)

      output
    end
  end

  defp parse_exif(output) do
    IO.puts("Parsing Exif Tags...")

    output
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "\t"))
    # Reject empty results
    |> Enum.reject(fn i -> Enum.count(i) == 1 end)
    |> Enum.map(fn [creation_date, date_time_original, modify_date, filename] ->
      %{
        creation_date: parse_date(creation_date),
        date_time_original: parse_date(date_time_original),
        modify_date: parse_date(modify_date),
        filename: filename
      }
    end)
  end

  defp write_exif_results(files) do
    content =
      files
      |> Enum.map(fn
        %{
          creation_date: creation_date,
          date_time_original: date_time_original,
          modify_date: modify_date,
          filename: filename
        } ->
          "creation_date: #{creation_date} date_time_original: #{date_time_original} modify_date: #{modify_date} filename #{filename}"
      end)
      |> Enum.join("\n")

    File.write!("exif_parsed_results.txt", content)

    files
  end

  defp parse_date("-"), do: "-"
  defp parse_date(date), do: date |> Timex.parse!("%Y-%m-%d %H:%M:%S", :strftime)

  def select_date_field(%{
        creation_date: creation_date,
        date_time_original: date_time_original,
        modify_date: modify_date,
        filename: filename
      }) do
    cond do
      Timex.is_valid?(date_time_original) ->
        %{filename: filename, date: date_time_original}

      Timex.is_valid?(creation_date) ->
        %{filename: filename, date: creation_date}

      Timex.is_valid?(modify_date) ->
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
Renamer.process(path)
