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
  target_port       = var.container_port
}

module "ecs" {
  source = "./modules/ecs"

  region                = var.region
  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  cpu                   = var.cpu
  memory                = var.memory
  image                 = var.image
  container_port        = var.container_port
  desired_count         = var.desired_count
  log_retention         = var.log_retention
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity

  depends_on = [module.alb]
}
