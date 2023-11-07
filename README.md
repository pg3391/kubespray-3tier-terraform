## Requirements

- Terraform 0.12.0 or newer
- ansible > 2.10.0  < 2.15.0

## How to Use
```commandline
export TF_VAR_AWS_ACCESS_KEY_ID="www"
export TF_VAR_AWS_SECRET_ACCESS_KEY ="xxx"
export TF_VAR_AWS_SSH_KEY_NAME="yyy"
export TF_VAR_AWS_DEFAULT_REGION="zzz"
``` 

- Clone the repo:
  ```
   git clone kubespray-3tier-terraform
  ```

- Create a keypair in aws before you  start and make sure you've defined the same inside credentials.tfvars and terraform.tfvars
- Inside terraform.tfvars make sure if you want to create single AZ or multiple AZ cluster comment accordingly
- Update `contrib/terraform/aws/terraform.tfvars` with your data. By default, the Terraform scripts use Ubuntu 18.04 LTS (Bionic) as base image. If you want to change this behaviour, see note "Using other distrib than Ubuntu" below.
- Create an AWS EC2 SSH Key
- terraform init
- Run with `terraform apply --var-file="credentials.tfvars"` or `terraform apply` depending if you exported your AWS credentials


```commandline
terraform apply -var-file=credentials.tfvars


cp ~/Downloads/techperson.pem ~/.ssh/techperson.pem
chmod 600 ~/.ssh/techperson.pem
eval $(ssh-agent)
ssh-add -D
ssh-add ~/.ssh/techperson.pem

- run below from kubespray i.e root directory not from aws.
```

ansible-playbook -i ./inventory/hosts ./cluster.yml -e ansible_user=ubuntu -b --become-user=root --flush-cache
 
```commandline

- Terraform automatically creates an Ansible Inventory file called `hosts` with the created infrastructure in the directory `inventory`
- Ansible will automatically generate an ssh config file for your bastion hosts. To connect to hosts with ssh using bastion host use generated `ssh-bastion.conf`. Ansible automatically detects bastion and changes `ssh_args`

- From root directory run
```
  cd <rootdirectory>
  ssh -F ssh-bastion.conf ubuntu@ -> if this does not work logint bastion, ssh ubuntu@<bastion-ip> and from there login to master and copy kubeconfig file.
  sudo cat /etc/kubernetes/admin.conf
  mkdir ~/.kube/
  sudo cp -R /etc/kubernetes/admin.conf ~/.kube/config
  sudo chown ubuntu:ubuntu ~/.kube/config
```  

- Via Local Machine
```  
mkdir ~/.kube/
touch ~/.kube/kubeconfig 
```
edit kubeconfig to local host updating name of server, replace it by server: https://<aws_elb_dns_name>:6443, eg: kubernetes-nlb-Dev-Cluster-0733355862d9aa5c.elb.us-west-2.amazonaws.com


- Decommission or Cleanup Infrastructure
cd ~/Projects/kubespray_workspace/kubespray-2.15.1/contrib/terraform/aws/
  terraform destroy -var-file=credentials.tfvars
- Upgrade the Kubernetes Version
```
ansible-playbook -i ./inventory/hosts ./upgrade-cluster.yml -e ansible_user=ubuntu -b --become-user=root -e kube_version=<replace_kubernetes_version_you_want_to_upgrade> 
```

- Decommission or Cleanup Infrastructure
```
cd ~/Projects/kubespray_workspace/kubespray-2.15.1/contrib/terraform/aws/ 
  terraform destroy -var-file=credentials.tfvars 
```

- External Reference: https://www.densify.com/kubernetes-tools/kubespray/
