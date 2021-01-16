{
  # Zabbix Agent access to the server
  # Port 10050 - 10052
  sg-agent = [
  ];

  # SSH access to zabbix
  # Port 22
  sg-ssh = [
  ];

  # Security Groups to allow instances
  # access to Zabbix GUI/API via HTTPS
  # Port 443
  sg-https = [
  ];

  # VPC SG for the RDS DB Instance
  # Port : $rdsPort
  sg-db = [
    # VPC CIDR Block
    # this is needed so that the EC2 instance
    # can reach the RDS DB
    # Example
    # "10.100.18.0/24"
  ];
}
