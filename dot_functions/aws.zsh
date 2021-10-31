function sso() {
  local profile="$1"
  local role_name="$2"
  local sso_start_url sso_account_id region access_token credentials expiration
  local role role_choices all_roles choice id

  if [[ -n $profile ]]; then
    if [[ -n $(aws configure list-profiles | grep "$profile") ]]; then
      unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

      sso_start_url=$(aws --profile "$profile" configure get sso_start_url)
      sso_account_id=$(aws --profile "$profile" configure get sso_account_id)
      cache_file="$HOME/.aws/sso/cache/$(echo -n "$sso_start_url" | sha1sum | cut -d' ' -f1).json"

      if [[ -f $cache_file ]]; then
        expiration=$(cat "$cache_file" | jq -r '.expiresAt')
      fi

      if [[ $expiration < "$(TZ=UTC date +%FT%TZ)" ]]; then
        aws sso login --profile "$profile"
      fi

      read region access_token <<<"$(jq -r '.region + " " + .accessToken' "$cache_file")"

      if [[ -n $sso_start_url ]]; then
        if [[ -z $role_name ]]; then
          echo "No role specified, looking for available ones..."
          roles=$(aws sso list-account-roles --region "$region" --access-token "$access_token" --account-id "$sso_account_id" --query 'roleList[*].roleName' --output text)

          all_roles="$roles"
          declare -a role_choices
          while [[ -n $all_roles ]]; do
            read role all_roles <<< "$all_roles"
            role_choices+=("$role")
          done

          if [[ ${#role_choices[@]} -gt 1 ]]; then
            echo
            id=0
            for role in "${role_choices[@]}"; do
              ((id++))
              echo "    $id) $role"
            done
            echo

            while true; do
              echo -n "Please select a role (1-${#role_choices[@]}): "
              read choice

              if [[ $choice =~ ^[0-9]+$ && $choice -gt 0 && $choice -le ${#role_choices[@]} ]]; then
                if [[ -n $BASH_VERSION ]]; then
                  # Hack for 0-based arrays in bash
                  ((choice--))
                fi

                role_name="${role_choices[choice]}"
                break
              fi
            done
          else
            if [[ -n $BASH_VERSION ]]; then
              # Hack for 0-based arrays in bash
              role_name="${role_choices[0]}"
            else
              role_name="${role_choices[1]}"
            fi

            echo "Only one role is available: $role_name"
          fi

          echo "Assuming role $role_name"
        fi

        read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<<$(
          aws sso get-role-credentials \
            --region "$region" \
            --access-token "$access_token" \
            --account-id "$sso_account_id" \
            --role-name "$role_name" \
            --query 'roleCredentials | [@.accessKeyId, @.secretAccessKey, @.sessionToken] | join(`\t`, @)' \
            --output text
        )

	aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $profile
	aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $profile	
	aws configure set aws_session_token $AWS_SESSION_TOKEN --profile $profile
        # export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
      fi
    else
      echo 'Profile not found!'
    fi
  else
    echo 'Usage: sso <profile_name> [<role_name>]'
  fi
}

function assume-role() {
  local role_name="$1"
  local role_arn

  if [[ -n $role_name ]]; then
    role_arn=$(aws iam get-role --role-name "$role_name" --query Role.Arn --output text)

    read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< $(
      aws sts assume-role \
        --role-arn "$role_arn" \
        --role-session-name "aws-assume-$(date +%s)" \
        --query 'Credentials | [@.AccessKeyId, @.SecretAccessKey, @.SessionToken] | join(`\t`, @)' \
        --output text
    )

    echo "$AWS_ACCESS_KEY_ID\n$AWS_SECRET_ACCESS_KEY\n$region\n" | aws configure --profile $profile
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    unset AWS_PROFILE
  else
    echo "Usage: assume-role <role_name>"
  fi
}
