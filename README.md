# Photo Video Renamer

A script to rename pictures and videos to the date they have been taken.

## Installation

To run this script you first need to install [exiftool](https://exiftool.org/), a command line utility to read exif tags.  
It's available on Linux through many package managers and MacOS through direct download or through Homebrew:

```
brew install exiftool
```

You also need the Elixir runtime (> 0.12), see the `.tool-versions` file for the specific versions.

## Usage

Run the renaming script as follows:

```
elixir renamer.exs path_with_pics/
```

An `exif_results.txt` file will be written in the current directory for debugging.
