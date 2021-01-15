{
  zabbixServer ? "default"
, timezone ? "America/New_York"
, sslCert ? ""
, ...
}:
{

  defaults =
    { config, pkgs, name, resources, lib, ... }:
    {

     time.timeZone = lib.mkOverride 0 timezone;

      users.motd = ''

                                       Welcome to:
              ______.      ___       ______.    ______.  .__  ___    ___
             /___   /     /   \     |   _   \  |   _   \ |__| \  \  /  /
                /  /     /  .  \    |  <_>  /  |  <_>  / |  |  \  \/  /
               /  /     /  /-\  \   |   _  .   |   _  .  |  |   >    <
              /  /__.  /  /---\  \  |  <_>  \  |  <_>  \ |  |  /  /\  \
             /._____/ /__/     \__\ |______./  |______./ |__| /__/  \_ \
                                                                      \/


      '';
      environment.shellInit = ''
        export EDITOR=vim
      '';

      users.users.zabbix.extraGroups = [ "keys" "wwwrun" "postfix" ];
      users.users.wwwrun.extraGroups = [ "keys" ];

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      environment.systemPackages =
         with pkgs; [ vim mysql psql python3 awscli htop ];


      deployment.keys = {
        "ssl.crt" = {
          text = if sslCert != "" then builtins.readFile (<global_creds> + "/${sslCert}.crt") else "";
          group = "wwwrun";
          permissions = "0640";
        };
        "ssl.key" = {
          text = if sslCert != "" then builtins.readFile (<global_creds> + "/${sslCert}.key") else "";
          group = "wwwrun";
          permissions = "0640";
        };
        "zabbix-${zabbixServer}-pwd" = {
          text = builtins.readFile (<global_creds> + "/zabbix-db-${zabbixServer}");
          group = "wwwrun";
          permissions = "0640";
        };
      };

      services.postfix.enable = true;
    };

}
