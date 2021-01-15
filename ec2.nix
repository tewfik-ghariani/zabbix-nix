{
  zabbixServer ? "default"
, account ? "default"
, instanceType ? "m5.large"
, region ? "us-east-1"
, zone ? "us-east-1d"
, dnsName ? ""
, subnetId ? ""
, dnsZoneName ? ""
, ...
}:
{
  require = [
  ];

  defaults =
    { config, pkgs, name, resources, lib, ... }:
    {

      deployment.targetEnv = "ec2";
      deployment.ec2 = lib.mkDefault {
        region = region;
        zone = zone;
        subnetId = subnetId;
        elasticIPv4 = resources.elasticIPs."zabbix-${zabbixServer}-eipv4";
        securityGroupIds = [
          resources.ec2SecurityGroups."zabbix-${zabbixServer}-https-sg".name
          resources.ec2SecurityGroups."zabbix-${zabbixServer}-agent-sg".name
          resources.ec2SecurityGroups."zabbix-${zabbixServer}-ssh-sg".name
        ];
        ebsInitialRootDiskSize = 50;
        instanceType = instanceType;
        securityGroups = [];
        associatePublicIpAddress = true;
        accessKeyId = account;
        instanceProfile = resources.iamRoles."zabbix-${zabbixServer}-role".name;
        keyPair = resources.ec2KeyPairs."zabbix-${zabbixServer}-keypair".name;
        tags = {
          Name = "${config.deployment.name}.${name}";
          Project = "Zabbix";
        };
      };
    };

  resources.ec2KeyPairs."zabbix-${zabbixServer}-keypair" =
    {
      accessKeyId = account;
      inherit region;
    };

  resources.elasticIPs."zabbix-${zabbixServer}-eipv4" =
    {
      accessKeyId = account;
      inherit region;
      vpc = true;
    };

  resources.route53HostedZones."zabbix-${zabbixServer}-hosted-zone" =
    { config, resources, ... }:
    {
      accessKeyId = account;
      name = dnsZoneName;
    };

  resources.route53RecordSets."zabbix-${zabbixServer}-dns" =
    { config, resources, lib, ... }:
    {
      accessKeyId = account;
      zoneId = resources.route53HostedZones."zabbix-${zabbixServer}-hosted-zone";
      name = dnsName;
      domainName = "${dnsName}.";
      routingPolicy = "simple";
      recordType = "A";
      recordValues = [ resources.machines.machine ];
    };

  resources.iamRoles."zabbix-${zabbixServer}-role" =
    { lib, ... }:
    {
      accessKeyId = account;
      policy = builtins.toJSON
      {  Statement =
           [{
             Effect = "Allow";
             Action = [ "ses:SendEmail" "ses:SendRawEmail" ];
             Resource = "*";
           }];
      };
    };

}
