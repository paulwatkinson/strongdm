{strongdm-releases, ...}: let
  arch-replacements = {
    "amd64" = "x86_64";
    "386" = "i386";
  };
in
  builtins.foldl'
  (prev: {
      os,
      arch,
      software,
      version,
      ...
    } @ release: let
      system = "${arch-replacements.${arch} or arch}-${os}";
    in
      prev
      // {
        ${system} =
          (prev.${system} or {})
          // {
            ${software} =
              (prev.${system}.${software} or {})
              // {${version} = release;};
          };
      })
  {}
  (builtins.map
    builtins.fromJSON
    (builtins.filter
      (value: (builtins.isString value) && value != "")
      (builtins.split "\n" (builtins.readFile strongdm-releases))))
