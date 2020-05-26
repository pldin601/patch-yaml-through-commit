#!/bin/sh
set -e +u

if [ -z "$INPUT_GIT_REPO_URL" ]; then
    echo "Input git_repo_url is required!"
    exit 1
fi

if [ -z "$INPUT_YAML_FILE" ] || [ -z "$INPUT_PATCH_EXPRESSION" ]; then
    echo "Input yaml_file and patch_expression is required!"
    exit 1
fi

if [ -z "$INPUT_COMMIT_MESSAGE" ] || [ -z "$INPUT_COMMITTER_NAME" ] || [ -z "$INPUT_COMMITTER_EMAIL" ]; then
    echo "Input commit_message, committer_name and committer_email is required!"
    exit 1
fi

mkdir /code
cd /code

echo Cloning repository...
git clone -b "${INPUT_GIT_BRANCH}" "${INPUT_GIT_REPO_URL}" .

echo Patching yaml file...
for expr in $INPUT_PATCH_EXPRESSION; do
  PATH="${expr%=*}"
  VALUE="${expr#*=}"
  /yq w --inplace "$INPUT_YAML_FILE" "$PATH" "$VALUE"
done

if [ -n "${INPUT_DRY_RUN}" ]; then
  git diff HEAD "$INPUT_YAML_FILE"
  exit 0
fi

git config user.name "$INPUT_COMMITTER_NAME"
git config user.email "$INPUT_COMMITTER_EMAIL"

echo Adding patched file to commit...
git add "$INPUT_YAML_FILE"

echo Committing change...
git commit -m "$INPUT_COMMIT_MESSAGE"

echo Pushing...
git push
