defmodule Reader do
  @extension_whitelist ~w(.jpg .jpeg)

  def rename(filepath) do
  end

  def read_date(filepath) do
    {out, _status} = System.cmd("exiftool", ["-DateTimeOriginal", "-ee", filepath])
    IO.inspect(filepath <> " " <> out)
  end
end

path = "/Users/dario/Downloads/ireland_renamed/"

list = File.ls!(path)

out =
  list
  |> Enum.map(&Reader.read_date(path <> &1))

IO.puts(out)

# Command for MOV files:
# exiftool -CreationDate -ee filepath

# Command for JPEGS:
# exiftool -DateTimeOriginal -ee filepath

# Variant using exiv2:
# {out, _status} = System.cmd("exiv2", ["-g", "Exif.Image.DateTime", "-Pv", filepath])
