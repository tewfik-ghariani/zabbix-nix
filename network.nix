{
  zabbixServer ? "default"
, ...
}:
{

  network.description = "Zabbix ${zabbixServer} NixOS";

  require = [
    ./ec2.nix
    ./nixos.nix
    ./zabbix.nix
    ./rds.nix
  ];

  machine =
    { config, pkgs, name, resources, lib, ... }:
    {

    } ;

}
