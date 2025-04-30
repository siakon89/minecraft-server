# minecraft-server
This is the code fromt he blogpost: https://www.thelastdev.com/p/learning-ecs-the-fun-way-hosting

You can run your own Minecraft server using ECS and Fargate, but this is not something that you can play in daily basis. This is way overpriced, and it's purpose is to understand ECS and it's components.

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
  whitelist_list = "<yout Minecraft Username>"
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