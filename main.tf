module "vpc" {
  source = "./modules/vpc"

  region             = var.region
  env                = var.env
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "alb" {
  source = "./modules/alb"

  region            = var.region
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  listener_port     = var.listener_port
  target_port       = var.app_container_port
  health_check_path = "/api/health"
}
