# Kubernetes on AWS with Terraform

## Overview

This project will create:

- VPC with Public and Private Subnets in # Availability Zones
- Bastion Hosts and NAT Gateways in the Public Subnet
- A dynamic number of masters, etcd, and worker nodes in the Private Subnet
  - even distributed over the # of Availability Zones
- AWS ELB in the Public Subnet for accessing the Kubernetes API from the internet

## Requirements

- Terraform 0.12.0 or newer

## How to Use

- Export the variables for your AWS credentials or edit `credentials.tfvars`:

```commandline
export TF_VAR_AWS_ACCESS_KEY_ID="www"
export TF_VAR_AWS_SECRET_ACCESS_KEY ="xxx"
export TF_VAR_AWS_SSH_KEY_NAME="yyy"
export TF_VAR_AWS_DEFAULT_REGION="zzz"
```

- Update `contrib/terraform/aws/terraform.tfvars` with your data. By default, the Terraform scripts use Ubuntu 18.04 LTS (Bionic) as base image. If you want to change this behaviour, see note "Using other distrib than Ubuntu" below.
- Create an AWS EC2 SSH Key
- Run with `terraform apply --var-file="credentials.tfvars"` or `terraform apply` depending if you exported your AWS credentials

Example:

```commandline
terraform apply -var-file=credentials.tfvars
```

- Terraform automatically creates an Ansible Inventory file called `hosts` with the created infrastructure in the directory `inventory`
- Ansible will automatically generate an ssh config file for your bastion hosts. To connect to hosts with ssh using bastion host use generated `ssh-bastion.conf`. Ansible automatically detects bastion and changes `ssh_args`

```commandline
ssh -F ./ssh-bastion.conf user@$ip
```

- Once the infrastructure is created, you can run the kubespray playbooks and supply inventory/hosts with the `-i` flag.

Example (this one assumes you are using Ubuntu)

```commandline
ansible-playbook -i ./inventory/hosts ./cluster.yml -e ansible_user=ubuntu -b --become-user=root --flush-cache
```

***Using other distrib than Ubuntu***
If you want to use another distribution than Ubuntu 18.04 (Bionic) LTS, you can modify the search filters of the 'data "aws_ami" "distro"' in variables.tf.

For example, to use:

- Debian Jessie, replace 'data "aws_ami" "distro"' in variables.tf with

```ini
data "aws_ami" "distro" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-jessie-amd64-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["379101102735"]
}
```

- Ubuntu 16.04, replace 'data "aws_ami" "distro"' in variables.tf with

```ini
data "aws_ami" "distro" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
```

- Centos 7, replace 'data "aws_ami" "distro"' in variables.tf with

```ini
data "aws_ami" "distro" {
  most_recent = true

  filter {
    name   = "name"
    values = ["dcos-centos7-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["688023202711"]
}
```

## Connecting to Kubernetes

You can use the following set of commands to get the kubeconfig file from your newly created cluster. Before running the commands, make sure you are in the project's root folder.

```commandline
# Get the controller's IP address.
CONTROLLER_HOST_NAME=$(cat ./inventory/hosts | grep "\[kube_control_plane\]" -A 1 | tail -n 1)
CONTROLLER_IP=$(cat ./inventory/hosts | grep $CONTROLLER_HOST_NAME | grep ansible_host | cut -d'=' -f2)

# Get the hostname of the load balancer.
LB_HOST=$(cat inventory/hosts | grep apiserver_loadbalancer_domain_name | cut -d'"' -f2)

# Get the controller's SSH fingerprint.
ssh-keygen -R $CONTROLLER_IP > /dev/null 2>&1
ssh-keyscan -H $CONTROLLER_IP >> ~/.ssh/known_hosts 2>/dev/null

# Get the kubeconfig from the controller.
mkdir -p ~/.kube
ssh -F ssh-bastion.conf centos@$CONTROLLER_IP "sudo chmod 644 /etc/kubernetes/admin.conf"
scp -F ssh-bastion.conf centos@$CONTROLLER_IP:/etc/kubernetes/admin.conf ~/.kube/config
sed -i "s^server:.*^server: https://$LB_HOST:6443^" ~/.kube/config
kubectl get nodes
```

## Troubleshooting

### Remaining AWS IAM Instance Profile

If the cluster was destroyed without using Terraform it is possible that
the AWS IAM Instance Profiles still remain. To delete them you can use
the `AWS CLI` with the following command:

```commandline
aws iam delete-instance-profile --region <region_name> --instance-profile-name <profile_name>
```

### Ansible Inventory doesn't get created

It could happen that Terraform doesn't create an Ansible Inventory file automatically. If this is the case copy the output after `inventory=` and create a file named `hosts`in the directory `inventory` and paste the inventory into the file.

## Architecture

Pictured is an AWS Infrastructure created with this Terraform project distributed over two Availability Zones.

![AWS Infrastructure with Terraform  ](docs/aws_kubespray.png)
=====================================================================================
The next step is to clone the Kubespray repository into our jumpbox.

git clone https://github.com/kubernetes-sigs/kubespray.git
We then enter the cloned directory and copy the credentials.

cd kubespray/contrib/terraform/aws/
cp credentials.tfvars.example credentials.tfvars
After copying, fill out credentials.tfvars with our AWS credentials.

vim credentials.tfvars
In this case, the AWS credentials were as follows.

#AWS Access Key
AWS_ACCESS_KEY_ID = ""
#AWS Secret Key
AWS_SECRET_ACCESS_KEY = ""
#EC2 SSH Key Name
AWS_SSH_KEY_NAME = "Altoros-kubespray"
#AWS Region
AWS_DEFAULT_REGION = "us-east-2"
Next, we edit terraform.tfvars in order to customize our infrastructure.

vim terraform.tfvars
Below is an example configuration.

#Global Vars
aws_cluster_name = "altoros-cluster"

#VPC Vars
aws_vpc_cidr_block       = "10.250.192.0/18"
aws_cidr_subnets_private = ["10.250.192.0/20", "10.250.208.0/20"]
aws_cidr_subnets_public  = ["10.250.224.0/20", "10.250.240.0/20"]

#Bastion Host
aws_bastion_size = "t2.medium"

#Kubernetes Cluster

aws_kube_master_num  = 3
aws_kube_master_size = "t2.medium"

aws_etcd_num  = 3
aws_etcd_size = "t2.medium"

aws_kube_worker_num  = 4
aws_kube_worker_size = "t2.medium"

#Settings AWS ELB

aws_elb_api_port                = 6443
k8s_secure_api_port             = 6443
kube_insecure_apiserver_address = "0.0.0.0"

default_tags = {
  #  Env = "devtest"
  #  Product = "kubernetes"
}

inventory_file = "../../../inventory/hosts"
Next, initialize Terraform and run terraform plan to see any changes required for the infrastructure.

terraform init
terraform plan -out mysuperplan -var-file=credentials.tfvars
After, apply the plan that was just created. This begins deploying the infrastructure and may take a few minutes.

terraform apply “mysuperplan”
Once deployed, we can check out the infrastructure in our AWS dashboard.

AWS-dashboard-1024x576Deployed instances shown in the AWS dashboard
 

VI_22_900х150_2
 

Deploying a cluster with Kubespray
With the infrastructure provisioned, we can begin to deploy a Kubernetes cluster using Ansible. Start off by entering the Kubespray directory and use the Ansible inventory file created by Terraform.

cd ~/kubespray
cat inventory/hosts
Next, load the SSH keys, which were created in AWS earlier on. First, create a file (in our case, it will be located at ~/.ssh/Altoros/kubespray.pem) and paste the private part of the key created at AWS there.

cat “” > ~/.ssh/Altoros/kubespray.pem
eval $(ssh-agent)
ssh-add -D
ssh-add ~/.ssh/Altoros/kubespray.pem
Once the SSH keys are loaded, we can now deploy a cluster using Ansible playbooks. This takes roughly 20 minutes.

ansible-playbook -i ./inventory/hosts ./cluster.yml -e ansible_user=core -b --become-user=root --flush-cache
 

Configuring access to the cluster
Now that the cluster has been deployed, we can configure who has access to it. First, find the IP address of the first master.

cat inventory/hosts
After identifying the IP address, we can SSH to the first master.

ssh  -F ssh-bastion.conf core@10.250.200.182
Once connected, we are set as a core user. Switch to the root user and copy the kubectl config located in the root home folder.

sudo ~s
cd ~
cd .kube
cat config
Highlight and copy the kubectl config as shown in the following image.

kubectl-config-highlight-1024x576Example kubectl config
Return to the jumpbox and go to kube/config.

exit
vim ~/.kube/config
Paste the copied kubectl config here.

kubectl-config-paste-1024x576Copying kubectl config
Next, copy the URL of the load balancer from the inventory file. In our case, the URL is kubernetes-elb-altoros-cluster-458236357.us-east-2.elb-amazonaws.com. Paste this URL into the server parameter in kubectl config. Do not overwrite the port.

 

Running test deployments
After configuring access to the cluster, we can check on our cluster.

kubectl get nodes
kubectl cluster-info
Node and cluster details will be shown in the console.

kubernetes-cluster-and-node-details-1024x576Cluster and node details
With the cluster ready, we can run a test deployment.

kubectl create deployment nginx --image=nginx
kubectl get pods
kubectl get deployments
Entering this commands should deploy NGINX and also return the status of the pods and deployments.


https://www.altoros.com/blog/installing-kubernetes-with-kubespray-on-aws/