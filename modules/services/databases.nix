# Database Services
# MariaDB and PostgreSQL configuration
{ pkgs, ... }:

let
  constants = import ../../shared/constants.nix;
in {
  services = {
    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    postgresql = {
      enable = false;
      ensureDatabases = [ constants.user.name ];

      ensureUsers = [
        {
          name = constants.user.name;
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            createrole = true;
            createdb = true;
            bypassrls = true;
            "inherit" = true;
            replication = true;
          };
        }
      ];

      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
    };
  };

  # Don't auto-start MariaDB - use 'sudo systemctl start mysql' when needed
  systemd.services.mysql.wantedBy = pkgs.lib.mkForce [];
}
