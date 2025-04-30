# minecraft-server
This is the code fromt he blogpost: https://www.thelastdev.com/p/learning-ecs-the-fun-way-hosting

I have adjusted the code to decrease the cost of the minecraft server in ECS. This should cost approximately $26 per month.

## Deploying
To deploy the ECS and the Minecraft server, you can do the following:

### Configuration
Edit the `locals.tf` file
```hcl
locals {
  region = "eu-central-1"  # Select your region

  # Container
  container_port = 25565

  # Minecraft related
  whitelist_list = "<your Minecraft Username>"
  difficulty     = "hard"  # change difficulty if you want

  # VPC  - Feel free to change the CIDR block and subnets
  cidr            = "10.168.1.0/26"
  private_subnets = ["10.168.1.0/28", "10.168.1.16/28"]
  public_subnets  = ["10.168.1.32/28", "10.168.1.48/28"]
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
}
```

After the configuration, you can run the init to install modules
```bash
terraform init
```

And then provision the infrastructure
```bash
terraform apply
```