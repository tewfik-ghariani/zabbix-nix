{
  zabbixServer ? "default"
, region ? "us-east-1"
, emailFrom ? "zabbix@noreply.com"
, ownerDL ? "admin@noreply.com"
, emailTo ? "$1"
, dnsName ? ""
, rdsEngine ? "mysql"
, rdsPort ? 3306
, sslCert ? ""
, ...
}:
{

  defaults =
    { config, resources, pkgs, name, lib, ...}:
    let
      emailScript = pkgs.writeScript "email-script.sh" ''
        #!/run/current-system/sw/bin/bash
        source /etc/profile
        export zabbixemailfrom="${emailFrom}"
        export zabbixemailto="${emailTo}"
        export zabbixsubject="$2"
        export zabbixbody="$3"

        /run/current-system/sw/bin/aws ses send-email --from $zabbixemailfrom --to $zabbixemailto --subject "$zabbixsubject" --text "$zabbixbody" --region ${region}
        /run/current-system/sw/bin/logger "DONE - with AWS SES $zabbixemailto - $zabbixsubject"
      '';
      sslConfig = if sslCert != "" then
        {
          services.zabbixWeb.virtualHost.forceSSL = true;
          services.zabbixWeb.virtualHost.sslServerCert = "/run/keys/ssl.crt";
          services.zabbixWeb.virtualHost.sslServerKey = "/run/keys/ssl.key";
        }
        else {};
    in
    {

      environment.etc."zabbix/zabbix-email.sh".source = emailScript;

      services.zabbixServer = {
        enable = true;
        database = {
          createLocally = false;
          type = rdsEngine;
          port = rdsPort;
          name = resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".dbName;
          host = resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".endpoint;
          user = resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".masterUsername;
          passwordFile = "/run/keys/zabbix-${zabbixServer}-pwd";
        };
        listen.port = 10051;
        openFirewall = true;
        settings = {
          AlertScriptsPath = "/etc/zabbix";
          CacheSize = "512M";
          HistoryCacheSize = "512M";
          ValueCacheSize = "256M";
          TrendCacheSize = "512M";
          HousekeepingFrequency = 4;
          StartHTTPPollers = 4;
          StartPingers = 20;
          StartPollers = 80;
          StartPollersUnreachable = 5;
          StartTrappers = 40;
          Timeout = 4;
          UnreachablePeriod = 150;
        };
      };

      services.zabbixWeb = {
        enable = true;
        database = {
          type = rdsEngine;
          port = rdsPort;
          name = resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".dbName;
          host = resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".endpoint;
          user = resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".masterUsername;
          passwordFile = "/run/keys/zabbix-${zabbixServer}-pwd";

        };
        server = {
          port = 10051;
          address = "localhost";
        };
        virtualHost = {
          hostName = dnsName;
          adminAddr = ownerDL;
        };
      };
      imports = [ sslConfig ];

      services.zabbixAgent = {
        enable = true;
        server = "127.0.0.1";
      };


    };
}
