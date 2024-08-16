{
  pkgs,
  inputs,
  config,
  ...
}:
let
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in
{
  process-managers.process-compose = {
    # required to use process-compose 1.9.0+
    package = pkgs-unstable.process-compose;
    settings.processes.caddy.command = pkgs.lib.mkForce (toString (pkgs.writeShellScript "caddy" config.processes.caddy.exec));
  };

  services.caddy = {
    enable = true;

    config = ''
      {
        # Prevents binding to port 80 which would need root privileges
      	auto_https disable_redirects
      }
    '';

    virtualHosts."https://localhost:8443" = {
      extraConfig = ''
        root * public

        encode zstd gzip

        file_server

        log {
          output stderr
          format console
          level ERROR
        }
      '';
    };
  };

  scripts = {
    caddy.exec = ''
      ${pkgs.caddy}/bin/caddy "$@"
    '';
    process-compose.exec = ''
      ${pkgs-unstable.process-compose}/bin/process-compose "$@"
    '';
  };

  processes = {
    # required to keep process-compose running when caddy fails
    sleep.exec = "sleep 3600";
    caddy.process-compose = {
      # required to install its unique root certificate into the trust store
      is_elevated = true;
    };
  };
}
