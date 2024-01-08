final: prev: let
  beamPackages = prev.beam_minimal.packagesWith prev.beam_minimal.interpreters.erlang_26;
  elixir = beamPackages.elixir_1_16;
  inherit (beamPackages) erlang;
in {
  inherit elixir erlang;

  beamPackages = beamPackages.extend (final: prev: {
    inherit elixir;

    buildHex = prev.buildHex.override {inherit elixir;};
    buildMix = prev.buildMix.override {inherit elixir;};
    fetchMixDeps = prev.fetchMixDeps.override {inherit elixir;};
    mixRelease = prev.mixRelease.override {inherit elixir;};

    mixRunTask = prev.callPackage ./mix_run_task.nix {
      inherit elixir;
    };
  });
}
