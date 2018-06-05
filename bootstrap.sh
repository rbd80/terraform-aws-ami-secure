#!/bin/bash
function assert_is_installed {
  local readonly name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    log_error "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

function create_policy {
    aws iam create-policy --policy-name $ID-Policy --policy-document file://aws/aws_iam_policy_$ID.json --profile $AWS_PROFILE
}
function create_user {
# ---------------------------------------------------------------------------------------------------------------------
# Create AWS account with policies and add to IaaS group
# ---------------------------------------------------------------------------------------------------------------------
    aws iam create-user --user-name $ID --profile $AWS_PROFILE
    aws iam add-user-to-group --group-name $ADMIN_GROUP --user-name $ID --profile $AWS_PROFILE
    aws iam attach-user-policy --user-name $ID --policy-arn "arn:aws:iam::$AWS_ACCOUNT_ID:policy/$ID-Policy" --profile $AWS_PROFILE
    aws iam create-access-key --user-name $ID --profile GSA > $ID.json
}

function create_iaas_accounts {
# ---------------------------------------------------------------------------------------------------------------------
# Assume if group created the accounts are setup
# ---------------------------------------------------------------------------------------------------------------------
    echo "Creating IaaS accounts"
    aws iam create-group --group-name $ADMIN_GROUP --profile $AWS_PROFILE
    # Terraform #
    for ID in $ADMIN_USERS
    do
        create_policy
        create_user
    done
}

function add_new_profile {
# ---------------------------------------------------------------------------------------------------------------------
# Create keys to be used for terraform and packer to use and add them to AWS Configure profile
# ---------------------------------------------------------------------------------------------------------------------
    #TODO I know this is back, but I don't know how to do manage aws creds any better
    cp ~/.aws/credentials ~/.aws/credentials.backup
    for ID in $ADMIN_USERS
     do
     ak=($(jq -r '.AccessKey.AccessKeyId' $ID.json))
     kk=($(jq -r '.AccessKey.SecretAccessKey' $ID.json))
             cat  <<EOT >> ~/.aws/credentials

[$ID]
aws_access_key_id = $ak
aws_secret_access_key = $kk
region=us-east-1
EOT

done
}
function delete_policy {
# ---------------------------------------------------------------------------------------------------------------------
# Delete policies
# ---------------------------------------------------------------------------------------------------------------------
    aws iam delete-policy --policy-arn "arn:aws:iam::$AWS_ACCOUNT_ID:policy/$ID-Policy" --profile $AWS_PROFILE
}
function delete_user {
# ---------------------------------------------------------------------------------------------------------------------
# Delete AWS account
# ---------------------------------------------------------------------------------------------------------------------
    ak=($(aws iam list-access-keys --user-name $ID --profile $AWS_PROFILE | jq -r '.AccessKeyMetadata[].AccessKeyId'))
    # aws iam list-access-keys --user-name terraform_svc --profile GSA | jq -r '.AccessKeyMetadata[].AccessKeyId'
    aws iam delete-access-key --access-key $ak --user-name $ID --profile $AWS_PROFILE
    aws iam detach-user-policy --user-name $ID --policy-arn "arn:aws:iam::$AWS_ACCOUNT_ID:policy/$ID-Policy" --profile $AWS_PROFILE
    aws iam remove-user-from-group --user-name $ID --group-name $ADMIN_GROUP --profile $AWS_PROFILE
    aws iam delete-user --user-name $ID --profile $AWS_PROFILE
}
function delete_iaas_accounts {
# ---------------------------------------------------------------------------------------------------------------------
# Assume if group created the accounts are setup
# ---------------------------------------------------------------------------------------------------------------------
    echo "Delete IaaS accounts"
    # Terraform #
    for ID in $ADMIN_USERS
    do
        delete_user
        delete_policy
    done
    aws iam delete-group --group-name $ADMIN_GROUP --profile $AWS_PROFILE
    #TODO I know this is back, but I don't know how to do manage aws creds any better
    cp ~/.aws/credentials.backup ~/.aws/credentials

}
function remove_aws_info {
# ---------------------------------------------------------------------------------------------------------------------
# Delete the keys that were downloaded
# ---------------------------------------------------------------------------------------------------------------------
    for ID in $ADMIN_USERS
    do
        rm -rf $ID.json
    done
}
function packagecheck {
# ---------------------------------------------------------------------------------------------------------------------
# Make sure some packages are installed
# ---------------------------------------------------------------------------------------------------------------------
  assert_is_installed "jq"
  assert_is_installed "terraform"
  assert_is_installed "curl"
}
function terraform_init {
# ---------------------------------------------------------------------------------------------------------------------
# Have Terraform create the AWS Codepipline for the secure AMIs
# ---------------------------------------------------------------------------------------------------------------------
    cd terraform
    terraform init -input=false
}

function terraform_backend {
    cd terraform
    cat << EOF > terraform.tfvars
#!/bin/bash -v
AWS_REGION = "$AWS_REGION"
profile = "terraform_svc"
NAMESPACE = "$NAMESPACE"
STAGE = "$STAGE"
GITTOKEN = "$GITTOKEN"
AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID
GITREPO = "$GITREPO"
GITOWNER = "$GITOWNER"
EOF

}

function terraform_plan {
# ---------------------------------------------------------------------------------------------------------------------
# Have Terraform create the AWS Codepipline for the secure AMIs
# ---------------------------------------------------------------------------------------------------------------------
    echo $NAMESPACE ... $GITOWNER ... $GITREPO ... $GITOWNER ... $STAGE ... $AWS_REGION ... $GITTOKEN ... $AWS_ACCOUNT_ID
    #terraform plan -var 'NAMESPACE=$NAMESPACE' -var 'GITOWNER=$GITOWNER' -var 'GITREPO=$GITREPO' -var 'GITOWNER=$GITREPO' -var 'STAGE=$STAGE' -var 'AWS_REGION=$AWS_REGION' -var 'GITTOKEN=$GITTOKEN' -var 'AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID' -out=tfplan -input=false
    terraform plan -var-file="terraform.tfvars" -out=tfplan -input=false
}

function terraform_apply {
# ---------------------------------------------------------------------------------------------------------------------
# Have Terraform create the AWS Codepipline for the secure AMIs
# ---------------------------------------------------------------------------------------------------------------------
    terraform apply -input=false tfplan
}

function terraform_delete {
# ---------------------------------------------------------------------------------------------------------------------
# Have Terraform create the AWS Codepipline for the secure AMIs
# ---------------------------------------------------------------------------------------------------------------------
    cd terraform
    terraform destroy -var-file="terraform.tfvars" -input=false
    rm -rf terraform.tfstate && rm -rf terraform.tfstate.backup && rm -rf tfplan && cd ..
}

function terrform_build {
		terraform_init
		terraform_backend
		terraform_plan
        terraform_apply
}
# ---------------------------------------------------------------------------------------------------------------------
# Create the code pipeline
# ---------------------------------------------------------------------------------------------------------------------
#init_terraform

# ---------------------------------------------------------------------------------------------------------------------
# Main Run section & Pretty menu
# ---------------------------------------------------------------------------------------------------------------------
cd `dirname $0`
[ -d ../data ] || mkdir ../data
[[ -s ./env.rc ]] && source ./env.rc

drawMenu() {
	# clear the screen
	tput clear

	# Move cursor to screen location X,Y (top left is 0,0)
	tput cup 3 15

	# Set a foreground colour using ANSI escape
	tput setaf 3
	echo "Setup a Secure AMI for Kubernetes to use"
	tput sgr0

	tput cup 5 17
	# Set reverse video mode
	tput rev
	echo "M A I N - M E N U"
	tput sgr0

	tput cup 7 15
	echo "1. Setup and begin the Secure OS build (Terraform & Packer)"

	tput cup 8 15
	echo "2. Create the AWS Pipeline, Terraform"

	tput cup 9 15
	echo "3. Harden Cluster"

	tput cup 10 15
	echo "4. Delete the AWS Pipeline, Terraform "

	tput cup 12 15
	echo "5. Delete AWS service account for Terraform & Packer"

	# Set bold mode
	tput bold
	tput cup 14 15
	# The default value for PS3 is set to #?.
	# Change it i.e. Set PS3 prompt
	read -p "Enter your choice [1-5] " choice
}

drawMenu
tput sgr0
# set deployservice list
case $choice in
	1)
		echo "#########################"
		echo "Creating Accounts"
        packagecheck
        create_iaas_accounts
        add_new_profile
        remove_aws_info
		echo "#########################"
		;;
	2)
		echo "#########################"
		echo "Create the AWS Pipeline, Terraform "
        terrform_build
		echo "#########################"
		;;
	3)
		echo "#########################"
		echo "Toughen up Kubernetes."
		#get_cluster_cfg
		build_template_cluster
		#ssh -i "${NAME}.pem" "admin@api.${NAME}"
		#ssh -i production.solveblock.org.pem.pub admin@ip-172-20-35-10.ec2.internal
		echo "#########################"
		;;
	4)
		echo "#########################"
		echo "Delete the AWS Pipeline, Terraform "
		terraform_delete
		echo "#########################"
		;;
	5)
		echo "#########################"
		echo "Destroy the accounts."
		delete_iaas_accounts
		echo "#########################"
		;;
	*)
		echo "Error: Please try again (select 1..5)!"
		;;
esac



