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
/*
        path = with pkgs; [ mysql postgresql ];
        serviceConfig.Type = "oneshot";
        script = ''
         echo "Initializing Zabbix DB"


         if [[ "${rdsEngine}" == "psql" ]]
         then
           echo "Postgres Database initialization is not supported yet."
         fi
       '';
      };


      systemd.services.zabbix-server.preStart.apply = ''
        # DB Params
        db_user="${resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".masterUsername}"
        db_pwd="$(cat /run/keys/zabbix-${zabbixServer}-pwd)"
        db_host="${resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".endpoint}"
        db_name="${resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db".dbName}"
        if [[ "${rdsEngine}" == "mysql"  ]]
        then
          echo "Mysql Database"
          db_tables=$(mysql -u $db_user --password=$db_pwd -h $db_host -e "USE $db_name; SHOW tables;" | wc -l)
          if [[ $db_tables == 0 ]]
          then
            echo "Importing inital schemas"
            # echo ${pkgs.zabbix}
            #ls -l ${pkgs.zabbix}/share/zabbix/database/mysql
            cat ${pkgs.zabbix}/share/zabbix/database/mysql/schema.sql | ${pkgs.mysql}/bin/mysql -u $db_user --password=$db_pwd -h $db_host
            cat ${pkgs.zabbix}/share/zabbix/database/mysql/images.sql | ${pkgs.mysql}/bin/mysql -u $db_user --password=$db_pwd -h $db_host
            cat ${pkgs.zabbix}/share/zabbix/database/mysql/data.sql | ${pkgs.mysql}/bin/mysql -u $db_user --password=$db_pwd -h $db_host
          else
            echo "Tables already exist."
          fi
        fi
      '';
      systemd.services.zabbix-server.wants = lib.mkOverride 0 [ "init-db" ];
*/
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
