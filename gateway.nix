{ pkgs, lib, config, nodes, nodeName, ... }:
with lib;

let
  cfg = config.modules.ff-gateway;

  enabledDomains = lib.filterAttrs (_: domain: domain.enable) cfg.domains;

  enabledFastdUnits = lib.mapAttrsToList (name: domain: lib.mkIf domain.fastd.enable "${config.services.fastd.${name}.unitName}.service") enabledDomains;

  intToHex = import ./functions/intToHex.nix { inherit lib; };
in
{

  options.modules.ff-gateway = {
    enable = mkEnableOption "ffda gateway";

    outInterface = mkOption {
      type = types.str;
      description = ''
        Interface used for connecting to the internet.
      '';
      default = "enp1s0";
    };

    meta = {
      contact = mkOption {
        type = types.str;
        description = "Contact Information. Announced via respondd if enabled.";
        default = "";
      };
      latitude = mkOption {
        type = types.str;
        description = "Latitude of the server. Announced via respondd if enabled.";
        default = "";
      };
      longitude = mkOption {
        type = types.str;
        description = "Longitude of the server. Announced via respondd if enabled.";
        default = "";
      };
    };

    respondd = {
      enable = mkEnableOption "enable mesh-announce" // { default = true; };
    };

    yanic = {
      enable = mkEnableOption "enable yanic";
    };

    domains = mkOption {
      type = with types; attrsOf  (submodule({ name, ...}: {
        options = {
          enable = mkEnableOption "enable domain" // { default = true; };
          name = mkOption {
            description = "Name of the domain";
            type = types.str;
            default = name;
          };
          id = mkOption {
            description = "ID of the domain";
            type = types.int;
            default = lib.strings.toIntBase10 (lib.strings.removePrefix "dom" name);
          };
          idHex = mkOption {
            description = "ID of the domain as hex representation";
            type = types.str;
            default = intToHex config.modules.ff-gateway.domains.${name}.id;
          };
          mtu = mkOption {
            description = "MTU of the domain";
            type = types.int;
            default = 1280;
          };
          dnsSearchDomain = mkOption {
            description = "DNS search domain of the domain";
            type = types.listOf types.str;
            default = [];
          };
          batmanAdvanced = {
            enable = mkEnableOption "start batman-adv for this domain" // { default = true; };
            mac = mkOption {
              type = types.str;
              description = ''
                MAC address of the batman-adv interface.
              '';
            };
            interfaceName = mkOption {
              type = types.str;
              description = ''
                Name of the batman-adv interface.
              '';
              default = "bat-${name}";
              readOnly = true;
            };
          };
          vxlan = {
            enable = mkEnableOption "start vxlan for this domain" // { default = true; };
            vni = mkOption {
              type = types.int;
              description = ''
                VXLAN ID
              '';
              default = config.modules.ff-gateway.domains.${name}.id;
            };
            interfaceName = mkOption {
              type = types.str;
              description = ''
                Name of the vxlan interface.
              '';
              default = "vx-${name}";
              readOnly = true;
            };
          };
          fastd = {
            enable = mkEnableOption "start fastd for this domain" // { default = true; };
            secretKeyIncludeFile = mkOption {
              type = types.str;
              description = ''
                Path to the fastd secret key file.
              '';
            };
            port = mkOption {
              type = types.port;
              description = ''
                Fastd listening port
              '';
            };
            peerInterfacePattern = mkOption {
              type = types.str;
              description = ''
                Name of the fastd interface.
              '';
              default = "${name}p-%k";
            };
            peerDir = mkOption {
              type = types.path;
              description = ''
                Path to the fastd peer directory.
              '';
            };
          };
          bird = {
            enable = mkEnableOption "start bird for this domain" // { default = true; };
          };
          ipv4 = {
            enable = mkEnableOption "start ipv4 for this domain" // { default = true; };
            subnet = mkOption {
              type = types.str;
              description = ''
                IPv4 subnet of this domain.
              '';
            };
            subnetNetwork = mkOption {
              type = types.str;
              description = ''
                IPv4 subnet network address of this domain.
              '';
              default = builtins.elemAt (lib.splitString "/" config.modules.ff-gateway.domains.${name}.ipv4.subnet) 0;
              readOnly = true;
            };
            subnetLength = mkOption {
              type = types.str;
              description = ''
                IPv4 subnet length of this domain in CIDR notation.
              '';
              default = builtins.elemAt (lib.splitString "/" config.modules.ff-gateway.domains.${name}.ipv4.subnet) 1;
              readOnly = true;
            };
            address = mkOption {
              type = types.str;
              description = ''
                IPv4 address for the current node.
              '';
            };
            addressCIDR = mkOption {
              type = types.str;
              description = ''
                IPv4 address for the current node in CIRDR notation.
              '';
              default = "${config.modules.ff-gateway.domains.${name}.ipv4.address}/${config.modules.ff-gateway.domains.${name}.ipv4.subnetLength}";
              readOnly = true;
            };
            dhcpV4 = {
              enable = mkEnableOption "start DHCPv4 server for this domain" // { default = true; };
              dnsServers = mkOption {
                type = types.listOf types.str;
                description = ''
                  List of DNS servers to send to DHCP clients.
                '';
                default = [];
              };
              gateway = mkOption {
                type = types.str;
                description = ''
                  Gateway IP to send to DHCP clients.
                '';
                default = config.modules.ff-gateway.domains.${name}.ipv4.address;
              };
              pools = mkOption {
                type = types.listOf types.str;
                description = ''
                  List of DHCPv4 pools to use.
                '';
                default = [];
              };
            };
          };
          ipv6 = {
            enable = mkEnableOption "start ipv6 for this domain" // { default = true; };
            subnet = mkOption {
              type = types.str;
              description = ''
                IPv6 subnet of this domain.
              '';
            };
            subnetNetwork = mkOption {
              type = types.str;
              description = ''
                IPv6 subnet network address of this domain.
              '';
              default = builtins.elemAt (lib.splitString "/" config.modules.ff-gateway.domains.${name}.ipv6.subnet) 0;
              readOnly = true;
            };
            subnetLength = mkOption {
              type = types.str;
              description = ''
                IPv6 subnet length of this domain in CIDR notation.
              '';
              default = builtins.elemAt (lib.splitString "/" config.modules.ff-gateway.domains.${name}.ipv6.subnet) 1;
              readOnly = true;
            };
            address = mkOption {
              type = types.str;
              description = ''
                IPv6 address for the current node.
              '';
            };
            addressCIDR = mkOption {
              type = types.str;
              description = ''
                IPv6 address for the current node in CIRDR notation.
              '';
              default = "${config.modules.ff-gateway.domains.${name}.ipv6.address}/${config.modules.ff-gateway.domains.${name}.ipv6.subnetLength}";
              readOnly = true;
            };
          };
        };
      }));
    };
  };

  imports = [
    ./fastd.nix
    ./bird.nix
    ./fastd-peergroup-nodes.nix
    ./fastd-exporter
    ./firewall
    ./kea
    ./yanic.nix
    ./mesh-announce
  ];

  config = mkIf cfg.enable {

    # boot.kernelPackages = pkgs.linuxPackages_6_5;
    # boot.kernelPackages = pkgs.linuxPackages_5_10;

    boot.extraModulePackages = with config.boot.kernelPackages; [ batman_adv ];

    boot.kernelModules = [
      "nf_conntrack"
    ];

    boot.kernel.sysctl = {
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.conf.all.rp_filter" = 0;

      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;

      "net.netfilter.nf_conntrack_max" = 256000;

      "net.ipv4.neigh.default.gc_thresh1" = 2048;
      "net.ipv4.neigh.default.gc_thresh2" = 4096;
      "net.ipv4.neigh.default.gc_thresh3" = 8192;

      "net.ipv6.neigh.default.gc_thresh1" = 2048;
      "net.ipv6.neigh.default.gc_thresh2" = 4096;
      "net.ipv6.neigh.default.gc_thresh3" = 8192;

      "net.core.rmem_default" = 8388608;
      "net.core.rmem_max" = 8388608;

      "net.core.wmem_default" = 8388608;
      "net.core.wmem_max" = 8388608;
    };

    services.freifunk.bird = {
      enable = true;
    };

    networking.firewall.allowedUDPPorts = lib.mapAttrsToList
    (name: domain: domain.fastd.port)
    (lib.filterAttrs (_: domain: domain.fastd.enable) enabledDomains);

    nixpkgs.overlays = [(self: super: {
      fastd = super.fastd.overrideAttrs (oldAttrs: {
        version = "22-unstable-2023-08-25";
        src = pkgs.fetchFromGitHub {
          owner  = "neocturne";
          repo = "fastd";
          rev = "2456f767edc67210797ae6a5b8a31aad83ea8296";
          sha256 = "sha256-iSZPBZnZUgcKVRJu/+ckwR1fQJFWGOc1bfWDCd71VlE=";
        };
      });
    })];

    services.fastd-exporter = {
      enable = true;
      instances = lib.mapAttrs (name: domain: config.services.fastd.${name}.statusSocket) enabledDomains;
    };

    systemd.services.${config.services.fastd-exporter.unitName} = {
      after = enabledFastdUnits;
    };

    systemd.services.${config.services.fastd-peergroup-nodes.unitName} = {
      before = enabledFastdUnits;
    };

    services.fastd = mapAttrs
      (_: domain: lib.mkIf domain.fastd.enable {
        description = "Domain ${domain.name}";
        peerLimit = 20;
        interface = domain.fastd.peerInterfacePattern;
        mode = "multitap";
        peerDir = domain.fastd.peerDir;
        method = [ "null@l2tp" "null" ];
        bind = [ "any port ${toString domain.fastd.port}" ];
        secretKeyIncludeFile = domain.fastd.secretKeyIncludeFile;
        persistInterface = false;
        l2tpOffload = true;
      })
      enabledDomains;

    systemd.network = mkMerge (attrValues (mapAttrs (_: domain: {
      netdevs = {
        "75-${domain.name}p-peers" = mkIf domain.fastd.enable {
          netdevConfig = {
            Name = "${domain.name}p-peers";
            Kind = "bridge";
          };
          extraConfig = ''
            [Bridge]
            STP=off
          '';
        };
        "70-${domain.batmanAdvanced.interfaceName}" = mkIf domain.batmanAdvanced.enable {
          netdevConfig = {
            Kind = "batadv";
            Name = "${domain.batmanAdvanced.interfaceName}";
            MACAddress = "${domain.batmanAdvanced.mac}";
          };
          batmanAdvancedConfig = {
            GatewayMode = "server";
            OriginatorIntervalSec = "5";
            RoutingAlgorithm = "batman-iv";
            HopPenalty = 60;
          };
          extraConfig = ''
            [BatmanAdvanced]
            GatewayBandwidthDown=100M
            GatewayBandwidthUp=100M
          '';
        };
      };
      networks = {
        "77-vpn-${domain.name}-peer" = mkIf domain.fastd.enable {
          matchConfig = {
            Name = "${domain.name}p-*";
          };
          networkConfig = {
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
            Bridge = "${config.systemd.network.netdevs."75-${domain.name}p-peers".netdevConfig.Name}";
          };
          extraConfig = ''
            [Bridge]
            Isolated=True
          '';
        };
        "75-${domain.name}p-peers" = mkIf domain.fastd.enable {
          matchConfig = {
            Name = "${config.systemd.network.netdevs."75-${domain.name}p-peers".netdevConfig.Name}";
          };
          networkConfig = {
            IPv6AcceptRA = false;
            BatmanAdvanced = "${domain.batmanAdvanced.interfaceName}";
            LinkLocalAddressing = "ipv6";
          };
          linkConfig = {
            RequiredForOnline = false;
          };
        };
        "70-${domain.batmanAdvanced.interfaceName}" = mkIf domain.batmanAdvanced.enable {
          matchConfig.Name = "${domain.batmanAdvanced.interfaceName}";
          linkConfig = {
            RequiredForOnline = false;
          };
          networkConfig = {
            Address = [] ++ lib.optional domain.ipv6.enable domain.ipv6.addressCIDR ++ lib.optional domain.ipv4.enable domain.ipv4.addressCIDR;
            IPv6AcceptRA = false;
          };
          DHCP = "no";
          dhcpV4Config = {
            UseDNS = false;
            UseDomains = false;
            # RouteTable = cfg.routeTable;
          };
          extraConfig = ''
            [IPv6AcceptRA]
            UseDNS=false
            DHCPv6Client=false
            UseGateway=true
          '';
        };
      };
    }) enabledDomains));

    networking.nftables.tables.mangle.content = ''
      chain forward_extra {
        ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (_: domain: ''
          ip version 4 iifname "${domain.batmanAdvanced.interfaceName}" oifname { "bat-dom*", "${cfg.outInterface}", "wg-icvpn*" } tcp flags syn / syn,rst counter tcp option maxseg size set 1240 comment "mss clamping - ${domain.name} - v4"
          ip version 4 iifname { "bat-dom*", "${cfg.outInterface}", "wg-icvpn*" } oifname "${domain.batmanAdvanced.interfaceName}" tcp flags syn / syn,rst counter tcp option maxseg size set 1240 comment "mss clamping - ${domain.name} - v4"
          ip version 6 iifname "${domain.batmanAdvanced.interfaceName}" oifname { "bat-dom*", "${cfg.outInterface}", "wg-icvpn*" } tcp flags syn / syn,rst counter tcp option maxseg size set 1220 comment "mss clamping - ${domain.name} - v6"
          ip version 6 iifname { "bat-dom*", "${cfg.outInterface}", "wg-icvpn*" } oifname "${domain.batmanAdvanced.interfaceName}" tcp flags syn / syn,rst counter tcp option maxseg size set 1220 comment "mss clamping - ${domain.name} - v6"
        '') enabledDomains)}
      }
    '';

    services.kea.dhcp4.settings.subnet4 = lib.mapAttrsToList (_: domain: mkIf domain.ipv4.dhcpV4.enable {
      id = domain.id;
      subnet = domain.ipv4.subnet;
      interface = "${domain.batmanAdvanced.interfaceName}";
      option-data = []
        ++ lib.optional ((builtins.length domain.dnsSearchDomain) != 0)
          {
            space = "dhcp4";
            name = "domain-search";
            code = 119;
            data = "${lib.concatStringsSep ", " domain.dnsSearchDomain}";
          }
        ++ lib.optional ((builtins.length domain.ipv4.dhcpV4.dnsServers) != 0)
          {
            space = "dhcp4";
            name = "domain-name-servers";
            code = 6;
            data = "${lib.concatStringsSep ", " domain.ipv4.dhcpV4.dnsServers}";
          }
        ++ lib.optional (domain.ipv4.dhcpV4.gateway != "")
          {
            space = "dhcp4";
            name = "routers";
            code = 3;
            data = "${domain.ipv4.dhcpV4.gateway}";
          }
        ++ lib.optional (domain.mtu != "")
          {
            space = "dhcp4";
            name = "interface-mtu";
            code = 26;
            data = "${builtins.toString domain.mtu}";
            always-send = true;
          }
      #   ++ [
      #   {
      #     space = "dhcp4";
      #     name = "domain-name";
      #     code = 15;
      #     data = "darmstadt.freifunk.net";
      #   }
      # ]
      ;
      valid-lifetime = 320;
      max-valid-lifetime = 320;
      pools = [] ++ builtins.concatLists (lib.optional ((builtins.length domain.ipv4.dhcpV4.pools) != 0)
        (map (pool: { inherit pool; }) domain.ipv4.dhcpV4.pools)
      );
    }) enabledDomains;

    services.kea.dhcp4.settings.interfaces-config.interfaces = lib.mapAttrsToList (_: domain: mkIf domain.ipv4.dhcpV4.enable
      "${domain.batmanAdvanced.interfaceName}"
    ) enabledDomains;


    networking.nftables.tables.nixos-fw = {
      content = ''
        chain input_extra {
          ip version 4 iifname { "mesh*" } udp sport 68 udp dport 67 counter drop comment "drop dhcp: raw mesh"
          ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (_: domain: ''ip version 4 iifname { "${domain.batmanAdvanced.interfaceName}" } udp sport 68 udp dport 67 counter accept comment "accept dhcp: ${domain.name}"'') enabledDomains)}
        }
        chain forward_extra {
          ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (_: domain:
          ''
            ip saddr { ${domain.ipv4.subnet} } iifname "${domain.batmanAdvanced.interfaceName}" oifname "${cfg.outInterface}" counter accept
            # ip daddr { ${domain.ipv4.subnet} } oifname "${domain.batmanAdvanced.interfaceName}" iifname "${cfg.outInterface}" ct state established,related counter accept comment "accept related and established"
            ip6 saddr { ${domain.ipv6.subnet} } iifname "${domain.batmanAdvanced.interfaceName}" oifname "${cfg.outInterface}" counter accept
            # ip6 daddr { ${domain.ipv6.subnet} } oifname "${domain.batmanAdvanced.interfaceName}" iifname "${cfg.outInterface}" ct state established,related counter accept comment "accept related and established"
          '') enabledDomains)}
        }
      '';
    };

    services.yanic = {
      enable  = cfg.yanic.enable;
      settings = {
        respondd = {
          enable = true;
          synchronize = "1m";
          collect_interval = "1m";
          sites = {
            ffda = {
              domains = [
                "ffda_da_540_kelley"
                "ffda_da_530_ggw3"
              ];
            };
          };
          interfaces = builtins.map (domain: {
            ifname = "${domain.batmanAdvanced.interfaceName}";
            multicast_address = "ff05::2:1001";
            port = 10001;
          }) (builtins.attrValues enabledDomains);
        };
        webserver = {
          enable = false;
          bind = "127.0.0.1:8080";
        };
        nodes = {
          state_path = "/var/lib/yanic/state.json";
          prune_after = "7d";
          save_interval = "5s";
          offline_after = "10m";
          output = {
            meshviewer-ffrgb = [
              {
                enable = true;
                path = "/var/www/html/meshviewer/data/meshviewer.json";
                filter = {
                  no_owner = true;
                };
              }
            ];
          };
        };
        database = {
          delete_after = "7d";
          delete_interval = "1h";
        };
      };
    };

    systemd.services.yanic.preStart = mkIf cfg.yanic.enable ''
      ${pkgs.coreutils}/bin/mkdir -p /var/www/html/meshviewer/data/
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/yanic/
    '';

    services.meshAnnounce = mkIf cfg.respondd.enable {
      enable = true;
      openFirewall = true;
      defaultConfig = {
        # DefaultDomain = "dom0";
        DomainType = "batadv";
        Contact = cfg.meta.contact;
        VPN = false;
        Latitude = cfg.meta.latitude;
        Longitude = cfg.meta.longitude;
      };

      domainConfig = lib.mapAttrs' (domain: value: {
        name = domain;
        value = {
          BatmanInterface = value.batmanAdvanced.interfaceName;
          Interfaces = [
            "${value.name}p-peers"
            "vx-${value.name}"
          ];
          Hostname = "${value.name}.${if (config.networking.domain or null) != null then config.networking.fqdn else config.networking.hostName}";
          VPN = value.fastd.enable;
        };
      }) enabledDomains;
    };
  };

}