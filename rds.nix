{
  zabbixServer ? "default"
, account ? "default"
, region ? "us-east-1"
, emailTo ? "$1"
, vpcId ? "vpc-xxxxx"
, rulesFile ? "rules.nix"
, subnetId ? ""
, subnetIds ? []
, rdsEngine ? "mysql"
, rdsPort ? 3306
, rdsName ? "zabbixDB"
, rdsUsername ? "master"
, rdsClass ? "db.m3.xlarge"
, rdsStorage ? 200
, rdsSnapshot ? ""
, ...
}:
{

  resources.rdsDbInstances."zabbix-${zabbixServer}-rds-db" =
    { config, resources, ... }:
    {
      inherit region;
      accessKeyId = account;
      id = "zabbix-${zabbixServer}";
      snapshot = rdsSnapshot;
      instanceClass = rdsClass;
      allocatedStorage = rdsStorage;
      masterUsername = rdsUsername;
      masterPassword = builtins.readFile (<global_creds> + "/zabbix-db-${zabbixServer}");
      port = rdsPort;
      engine = rdsEngine;
      dbName = rdsName;
      multiAZ = true;
      subnetGroup = resources.rdsSubnetGroups."zabbix-${zabbixServer}-subnet-group".name;
      vpcSecurityGroups = [ resources.ec2SecurityGroups."zabbix-${zabbixServer}-rds-sg" ];
    };

  resources.rdsSubnetGroups."zabbix-${zabbixServer}-subnet-group" =
    {
      inherit region;
      accessKeyId = account;
      subnetIds = subnetIds ++ [ subnetId ];
    };

  resources.ec2SecurityGroups = with (import ./create-sg.nix { region = region; vpcId = vpcId; accessKeyId = account;});
    let
      rules = import ( ./. + "/${rulesFile}");
    in
    {
      "zabbix-${zabbixServer}-https-sg" = createSecurityGroups "zabbix-${zabbixServer}-https" "HTTPS access to Zabbix ${zabbixServer}" 443 443 rules."sg-https";
      "zabbix-${zabbixServer}-agent-sg" = createSecurityGroups "zabbix-${zabbixServer}-agent" "Agent access to zabbix" 10050 10052 rules."sg-agent";
      "zabbix-${zabbixServer}-ssh-sg" = createSecurityGroups "zabbix-${zabbixServer}-ssh" "SSH server access to zabbix" 22 22 rules."sg-ssh";
      # We cannot whitelist the private IP of the zabbix server via nixops for now
      # So we whitelist the whole vpc CIDR
      "zabbix-${zabbixServer}-rds-sg" = createSecurityGroups "zabbix-${zabbixServer}-rds-db" "Security group for Zabbix ${zabbixServer} RDS" rdsPort rdsPort rules."sg-db";
    };

}
