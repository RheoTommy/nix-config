# Ovis (herdr-web-ui), a browser UI for herdr sessions.
#
# The version stays as pinned until bumped by hand. To move to a new release,
# change `version` and refresh the two hashes it fixes: the source and the
# installed node_modules. `nix-update --flake ovis --subpackage node_modules`
# does all three.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  nodejs,
  makeBinaryWrapper,
  autoPatchelfHook,
  writableTmpDirAsHomeHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ovis";
  version = "0.4.16";

  src = fetchFromGitHub {
    owner = "devswha";
    repo = "herdr-web-ui";
    tag = "v${finalAttrs.version}";
    hash = "sha256-kYZh9AOPYbmewwZeZkxuQ6w/mEbOQNI78bdHH7RPcws=";
  };

  nativeBuildInputs = [
    bun
    makeBinaryWrapper
    autoPatchelfHook
  ];
  # The prebuilt native modules, such as the PTY binding, link libstdc++.
  buildInputs = [ stdenv.cc.cc.lib ];
  # bun installs both the glibc and the musl builds of some native modules
  # and loads the one matching the host. The musl ones are never loaded here.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  configurePhase = ''
    runHook preConfigure
    # The build writes a cache into node_modules, so it needs its own copy.
    cp -R ${finalAttrs.passthru.node_modules} node_modules
    chmod -R u+w node_modules
    # vite's native plugins are loaded during the build, before fixup would
    # patch them.
    autoPatchelf node_modules
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    # The package's `bun run build`, minus the lookup through node_modules/.bin,
    # whose `#!/usr/bin/env node` scripts cannot run in the build sandbox.
    bun --bun ./node_modules/vite/bin/vite.js build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    # The server imports from shared/, src/ and scripts/ besides server/, and
    # serves the client from dist/ next to it.
    mkdir -p $out/share/ovis
    cp -R . $out/share/ovis
    rm -rf $out/share/ovis/node_modules/.cache
    # The server runs the PTY host under a real Node, found on PATH. Other
    # tools, such as herdr and tailscale, come from the caller's PATH.
    makeWrapper ${lib.getExe bun} $out/bin/ovis \
      --add-flags "run --no-install $out/share/ovis/server/index.ts" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}
    runHook postInstall
  '';

  passthru = {
    # bun.lock pins every package, so the installed tree is reproducible and
    # can be fetched with network access as a fixed-output derivation.
    node_modules = stdenvNoCC.mkDerivation {
      pname = "${finalAttrs.pname}-node_modules";
      inherit (finalAttrs) version src;

      impureEnvVars = lib.fetchers.proxyImpureEnvVars;
      nativeBuildInputs = [
        bun
        writableTmpDirAsHomeHook
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild
        # No dependency needs an install script; the native modules come as
        # prebuilt platform packages.
        bun install --frozen-lockfile --ignore-scripts --no-progress
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        cp -R node_modules $out
        runHook postInstall
      '';

      # Fixup would rewrite shebangs to store paths, which a fixed-output
      # derivation may not reference.
      dontFixup = true;

      outputHash = "sha256-dcscZOAqV8VwL700z+8LkkqyFIBFu3b8yamEeX4nn8c=";
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };
  };

  meta = {
    description = "Browser UI for herdr terminal sessions";
    homepage = "https://github.com/devswha/herdr-web-ui";
    changelog = "https://github.com/devswha/herdr-web-ui/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ovis";
  };
})
