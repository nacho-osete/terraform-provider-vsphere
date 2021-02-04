#!/usr/bin/env bash

# TEMPLATE_URL may be changed to any appropriate ova file
# This example uses the Terraform Ignition provider, so OS customization is only supported for Fedora/RHEL CoreOS images
TEMPLATE_URL="https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/33.20210104.3.1/x86_64/fedora-coreos-33.20210104.3.1-vmware.x86_64.ova"
TEMPLATE_DC="$(grep "datacenter" "${TF_DIR}/terraform.tfvars" | awk '{print $3}' | tr -d \'\"\' )"
TEMPLATE_DS="$(grep "datastore_name" "${TF_DIR}/terraform.tfvars" | awk '{print $3}' | tr -d \'\"\' )"
TEMPLATE_POOL="$(grep "resource_pool" "${TF_DIR}/terraform.tfvars" | awk '{print $3}' | tr -d \'\"\' )"
TEMPLATE_NAME="$(grep "template_name" "${TF_DIR}/terraform.tfvars" | awk '{print $3}' | tr -d \'\"\' )"

EXISTING_TEMPLATE="$(govc find -type m -name "${TEMPLATE_NAME}" | head -n 1)"
if [ -n "${EXISTING_TEMPLATE}" ]; then
  govc object.rename "${EXISTING_TEMPLATE}" "${TEMPLATE_NAME}_archived_$(date +%s)"
fi

govc import.ova -dc="${TEMPLATE_DC}" -ds="${TEMPLATE_DS}" -pool="${TEMPLATE_POOL}" -name="${TEMPLATE_NAME}" "${TEMPLATE_URL}"
govc snapshot.create -dc="${TEMPLATE_DC}" -vm="${TEMPLATE_NAME}" clone-root
govc vm.markastemplate -dc="${TEMPLATE_DC}" "${TEMPLATE_NAME}"
