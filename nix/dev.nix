{pkgs}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs;
    [
      elixir
      glibcLocales
      hex
      mix2nix
      rebar3
      exiftool
    ]
    ++ lib.optionals stdenv.isLinux [
      inotify-tools
    ]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.apple_sdk.frameworks.CoreServices
    ];

  shellHook = ''
    export LANG=en_US.UTF-8
    export ERL_AFLAGS="-kernel shell_history enabled"
  '';
}
