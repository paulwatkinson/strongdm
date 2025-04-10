{package}: {
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.strongdm;
in {
  options.services.strongdm = {
    enable =
      (lib.mkEnableOption "strongdm")
      // {
        default = true;
      };

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "%h/.sdm";
    };

    relayToken = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.strongdm-daemon = {
      description = "StrongDM Daemon";

      serviceConfig = {
        Type = "simple";

        ExecStart = let
          script = pkgs.writeShellScript "strongdm-daemon" ''
            mkdir -p $SDM_HOME
            cd $SDM_HOME
            exec ${cfg.package}/bin/sdm listen --daemon
          '';
        in "${script}";

        Slice = "session.slice";
        Restart = "on-failure";
      };

      environment = {
        SDM_RELAY_TOKEN = cfg.relayToken;
        SDM_HOME = cfg.workingDirectory;
      };

      wantedBy = ["default.target"];
    };

    environment.systemPackages = [
      cfg.package
    ];
  };
}
