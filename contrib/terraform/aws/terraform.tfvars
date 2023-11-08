#Global Vars
aws_cluster_name = "Dev-Cluster"

#VPC Vars
aws_vpc_cidr_block       = "10.0.0.0/16"
#aws_cidr_subnets_private = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
#aws_cidr_subnets_public  = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]

# single AZ deployment 
aws_cidr_subnets_private = ["10.0.1.0/24"]
aws_cidr_subnets_public  = ["10.0.4.0/24"]
aws_cidr_subnets_private1 = ["10.0.2.0/24"]

# 3+ AZ deployment
#aws_cidr_subnets_private = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24","10.0.4.0/24"]
#aws_cidr_subnets_public  = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24","10.0.7.0/24"]
#aws_cidr_subnets_private1 = ["10.0.8.0/24","10.0.8.0/24","10.0.10.0/24","10.0.11.0/24" ]

#Bastion Host
aws_bastion_num  = 1
aws_bastion_size = "t3.small"

#Kubernetes Cluster
aws_kube_master_num       = 1
aws_kube_master_size      = "t3.medium"
aws_kube_master_disk_size = 10

aws_etcd_num       = 0
aws_etcd_size      = "t3.medium"
aws_etcd_disk_size = 10

aws_kube_worker_num       = 1
aws_kube_worker_size      = "t3.medium"
aws_kube_worker_disk_size = 10

#Settings AWS ELB
aws_nlb_api_port    = 6443
k8s_secure_api_port = 6443

default_tags = {
    Env = "Dev-Cluster"
  #  Product = "kubernetes"
}

inventory_file = "../../../inventory/hosts"
