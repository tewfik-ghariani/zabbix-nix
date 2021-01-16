# Zabbix on NixOs

Launch Zabbix on EC2 instance and RDS DB instance via nixops deployment tool

## Overview

The following resources will be provisioned and managed as part of this nixops deployment

```
+--------------------------------+
| ec2-instance                   |
| elastic-ip                     |
| aws-route53-recordset          |
| aws-route53-hosted-zone        |
| ec2-keypair                    |
| ec2-rds-dbinstance             |
| ec2-security-group for EC2     |
| ec2-security-group for RDS     |
| iam-role                       |
| rds-subnet-group               |
+--------------------------------+
```

## Details

These nix expressions allow the following :

- Creating an EC2 instance and configuring it
- Creating an elastic IP and associating it to the machine
- Enabling the **zabbix-server** systemd unit in a generic nix module
- Including zabbixWeb module for the **GUI**
- Creating the RDS DB Instance resource in VPC
- Creating RDS Subnet group and the VPC SG alongside
- Managing all instance security groups ( SSH, HTTPS, Zabbix Agent )
- Creating the Route53 hosted zone
- Creating the Route53 record set
- Whitelisting the whole VPC Cidr since the DNS of the zabbix server is resolved on the private IP
- Support the alerting via AWS SES
- Possibility to restore the RDS DB instance from snapshot


## Steps

### Create a new deployment

```
nixops create -d test-deployment $(pwd)/network.nix -I global_creds=/data/keys/zabbix
```

### Adjust the Security Groups' rules

- Add the VPC Cidr block in the "sg-db" of rules.nix

- Update the "sg-ssh" rules with your IP addresses

- Update the "sg-https" rules with your IP addresses

- Update the "sg-agent" rules with IP addresses of the monitored servers


### Set the following nix arguments

**Mandatory**


| Nix Arg     | Example                                 | Type   |
| :---        | ---                                     | :---:  |
| vpcId       | "vpc-a1b473b1"                          | String |
| subnetId    | "subnet-9714dbe1"                       | String |
| subnetIds   | [ "subnet-2fed62ba" "subnet-6639bae3" ] | Nix    |
| dnsZoneName | "example.com"                           | String |
| dnsName     | "zabbix.example.com"                    | String |


**Optional**


| Nix Arg      | Default              | Type   |
| :---         | ---                  | :---:  |
| account      | "default"            | String |
| region       | "us-east-1"          | String |
| zone         | "us-east-1d"         | String |
| instanceType | "m5.large"           | String |
| timezone     | "America/New\_York"  | String |
| sslCert      | ""                   | String |
| zabbixServer | "default"            | String |
| emailFrom    | "zabbix@noreply.com" | String |
| emailTo      | "$1"                 | String |
| ownerDL      | "admin@noreply.com"  | String |
| rdsEngine    | "mysql"              | String |
| rdsPort      | 3306                 | Nix    |
| rdsName      | "zabbixDB"           | String |
| rdsUsername  | "master"             | String |
| rdsClass     | "db.m3.xlarge"       | String |
| rdsStorage   | 200                  | Nix    |
| rdsSnapshot  | ""                   | String |


### Add the secret keys

Place the following secrets under `<global_creds>` :

- zabbix-db-${zabbixServer}

- ${sslCert}.crt & ${sslCert}.key ( optional )

### *Deploy!*

```
nixops deploy -d test-deployment
```

_Output_
```
nixops info -d test-deployment
```

```
$ nixops info -d zabbix-nix
Network name: zabbix-nix
Network UUID: 5db2c712-55e2-11eb-b862-41088537904a
Network description: Zabbix default NixOS
Nix expressions: /data/zabbix-nix/network.nix
Nix path: -I global_creds=/data/keys/zabbix
Nix arguments: region = "eu-central-1", zone = "eu-central-1a", vpcId = "vpc-abcdef", subnetId = "subnet-5381923", subnetIds = [ "subnet-123351a" "subnet-a12314314" ], dnsZoneName = "nixops.com", dnsName = "zabbix.nixops.com"

+-----------------------------+-----------------+-----------------------------------+-------------------------------------------------------------------------+---------------+
| Name                        |      Status     | Type                              | Resource Id                                                             | IP address    |
+-----------------------------+-----------------+-----------------------------------+-------------------------------------------------------------------------+---------------+
| zabbix-default-hosted-zone  |        Up       | aws-route53-hosted-zone           | /hostedzone/Z089234OZDBDWURI5SN8                                        |               |
| zabbix-default-dns          |        Up       | aws-route53-recordset             | zabbix.nixops.com.                                                      |               |
| machine                     | Up / Up-to-date | ec2 [eu-central-1a; m5.large]     | i-0f4eg4ga1d2fbce2c                                                     | 18.198.11.158 |
| zabbix-default-keypair      |        Up       | ec2-keypair [eu-central-1]        | charon-91233712-55e2-11eb-b862-41088537904a-zabbix-default-keypair      |               |
| zabbix-default-rds-db       |        Up       | ec2-rds-dbinstance [eu-central-1] | zabbix-default                                                          |               |
| zabbix-default-agent-sg     |        Up       | ec2-security-group [eu-central-1] | zabbix-default-agent                                                    |               |
| zabbix-default-https-sg     |        Up       | ec2-security-group [eu-central-1] | zabbix-default-https                                                    |               |
| zabbix-default-rds-sg       |        Up       | ec2-security-group [eu-central-1] | zabbix-default-rds-db                                                   |               |
| zabbix-default-ssh-sg       |        Up       | ec2-security-group [eu-central-1] | zabbix-default-ssh                                                      |               |
| zabbix-default-eipv4        |        Up       | elastic-ip [eu-central-1]         | eipalloc-07g65f23                                                       |               |
| zabbix-default-role         |        Up       | iam-role                          | charon-91233712-55e2-11eb-b862-41088537904a-zabbix-default-role         |               |
| zabbix-default-subnet-group |        Up       | rds-subnet-group                  | nixops-91233712-55e2-11eb-b862-41088537904a-zabbix-default-subnet-group |               |
+-----------------------------+-----------------+-----------------------------------+-------------------------------------------------------------------------+---------------+
```


## Remarks

- `subnetId` must exist in the `zone` specified
- SSL encryption is disabled by default, it gets enabled if you specify the `sslCert` nix arg
- If `sslCert` nix arg is specified, the `${sslCert}.crt` and `${sslCert}.key` files must be renamed depending on its value
- `emailTo` by default will be set to the destination addresses defined in the zabbix actions, unless overriden by a static recipient
- The `zabbix-db-${zabbixServer}` file should be named based on `zabbixServer`'s value
- If you would like to restore the RDS DB instance from snapshot, you can do so by specifying the `rdsSnapshot` nix argument

