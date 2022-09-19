{ deku }: { config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.deku-node;
  listToString = lib.strings.concatStringsSep ",";
in
{
  options.services.deku-node = {
    enable = mkEnableOption "deku node";

    port = mkOption {
      type = types.int;
      default = 4440;
      description = lib.mDoc "The port to listen to";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Open ports in the firewall for the deku node.";
    };

    secretPath = mkOption {
      type = types.path;
      description = "Path to the base58-encoded secret used as the Deku node's identity.";
      apply = builtins.readFile;
    };

    boostrapKeyPath = mkOption {
      type = types.path;
      description = "Path to the base58-encoded public key with which to verify signed bootstrap signals.";
      apply = builtins.readFile;
    };

    databaseUri = mkOption {
      type = types.path;
      default = "/var/lib/deku/db.sqlite";
      description = "A URI-encoded path to a SQLite database. Will be created it if it doesn't exist already.";
    };

    validators = mkOption {
      type = types.listOf types.str;
      description = "Key hashes of all validators in the network.";
      apply = listToString;
    };

    validatorUris = mkOption {
      type = types.listOf types.str;
      description = "Validator URI's used to join the network.";
      apply = listToString;
    };

    tezos = {
      consensusAddress = mkOption {
        type = types.str;
        description = "The address of the consensus contract on Tezos.";
      };

      discoveryAddress = mkOption {
        type = types.str;
        description = "The address of the discovery contract on Tezos.";
      };

      requiredConfirmations = mkOption {
        type = types.int;
        default = 2;
        description = "The number of blocks to wait before considering a Tezos block confirmed.";
      };

      rpcNode = mkOption {
        type = types.str;
        description = "The address of the discovery contract on Tezos.";
      };

      secretPath = mkOption {
        type = types.path;
        description = "Path to the base58-encoded ED25519 secret to use as the wallet for submitting Tezos transactions.";
        apply = builtins.readFile;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.deku-node = {
      description = "Deku node";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.nodejs-16_x ];
      environment = {
        DEKU_BOOTSTRAP_KEY = "${cfg.boostrapKeyPath}";
        DEKU_DATABASE_URI = "sqlite3://${cfg.databaseUri}";
        DEKU_PORT = "${builtins.toString cfg.port}";
        DEKU_SECRET = "${cfg.secretPath}";
        DEKU_TEZOS_CONSENSUS_ADDRESS = "${cfg.tezos.consensusAddress}";
        DEKU_TEZOS_DISCOVERY_ADDRESS = "${cfg.tezos.discoveryAddress}";
        DEKU_TEZOS_REQUIRED_CONFIRMATIONS = "${builtins.toString cfg.tezos.requiredConfirmations}";
        DEKU_TEZOS_RPC_NODE = "${cfg.tezos.rpcNode}";
        DEKU_TEZOS_SECRET = "${cfg.tezos.secretPath}";
        DEKU_VALIDATORS = "${cfg.validators}";
        DEKU_VALIDATOR_URIS = "${cfg.validatorUris}";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${deku}/bin/deku-node";
        Restart = "on-failure";
        StateDirectory = "deku";

        # Basic Hardening
        NoNewPrivileges = "yes";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        DevicePolicy = "closed";
        DynamicUser = "true";
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ProtectControlGroups = "yes";
        ProtectKernelModules = "yes";
        ProtectKernelTunables = "yes";
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
        RestrictNamespaces = "yes";
        RestrictRealtime = "yes";
        RestrictSUIDSGID = "yes";
        MemoryDenyWriteExecute = "no";
        LockPersonality = "yes";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}