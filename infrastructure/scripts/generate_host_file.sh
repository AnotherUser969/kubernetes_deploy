#!/bin/bash
#Создание ansible host файла из terraform output

echo [masters] > hosts
terraform -chdir="./infrastructure/terraform" output -json | jq -r '.masters_ips.value.internal[][]' >> hosts
echo [workers] >> hosts
terraform -chdir="./infrastructure/terraform" output -json | jq -r '.workers_ips.value.internal[][]' >> hosts
