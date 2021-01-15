{
  accessKeyId
, region ? "us-east-1"
, vpcId
, ...
}:
let
  mapping = args:
    map (ip: {
      inherit (args) fromPort toPort;
      sourceIp = "${ip}";
    }) args.ips;
in
{
  createSecurityGroups = name: description: fromPort: toPort: ips:
    {
      inherit region vpcId accessKeyId;
      name = name;
      description = "${description} via nixops";
      rules = mapping { inherit fromPort toPort ips; };
    };
}
