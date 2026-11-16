# nix-update, patched so that --flake works with Nix 2.35.
#
# Workaround: nix-update 1.16.0 evaluates a flake from the store path that
# `nix flake metadata` reports, but Nix 2.35 copies sources to the store lazily
# and does not create that path, so the evaluation fails. The patch is the fix
# proposed upstream in https://github.com/Mic92/nix-update/pull/692, carried
# here because no release has it yet.
#
# TODO: Delete this file and the patch, and run nixpkgs#nix-update in
# .github/workflows/update.yml again, once nixpkgs has a nix-update release
# with the fix. The patch then usually stops applying, which fails the Bump
# Ovis step.
{ nix-update }:

nix-update.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./nix-update-lazy-flake-source.patch ];
})
