echo "ECR REPOSITORY: $1";
echo "Previous Revision Number: $2";
new_revision_number=$2
is_exist_imagetag=true
is_exist_definition=true
# Check if Image Exist or not
while "$is_exist_imagetag"; do 
	echo "Checking $new_revision_number . revision"
	IMAGE_TAG=$(aws ecs describe-task-definition --task-definition "$1":"$new_revision_number" --query "taskDefinition.containerDefinitions[0].image" --output text |cut -d: -f2)
	if (aws ecr describe-images --repository-name=$1 --image-ids=imageTag="$IMAGE_TAG"&> /dev/null); then
		echo "IMAGE FOUND"
		echo "CHECKING TASK DEFINITION"
		# Check if definition exist or not
		while "$is_exist_definition"; do 
			if (aws ecs describe-task-definition --task-definition "$1:$new_revision_number" --output text &> /dev/null); then
				echo "TASK DEFINITION FOUND"
				is_exist_definition=false
				is_exist_imagetag=false
			else
				echo 'TASK DEFINITION IS NOT FOUND. Checking previous revision...'
				new_revision_number=$(( $new_revision_number - 1 ))
			fi
		done

		is_exist_imagetag=false
	else
		echo 'Image is Not Found on ECR. Checking previous revision...'
		new_revision_number=$(( $new_revision_number - 1 ))
	fi
done

echo "New revision number: $new_revision_number"
echo "NEW_PREVIOUS_REVISION_NUMBER"=$new_revision_number >> $GITHUB_ENV
echo $GITHUB_ENV