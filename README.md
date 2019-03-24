## cvs-api

## Overview
Bash scripts written to demonstrate the APIs for the NetApp Cloud Volumes service for AWS, to programmatically create, modify, clone, snap, revert and delete CVS volumes.

## What is Cloud Volume Services (CVS)?
NetApp's Cloud Voume Service provides high performance shared storage over NFS and SMB for AWS customers. For more info, head to https://cloud.netapp.com/cloud-volumes-service-for-aws

## API stuff
* Link to the API documentation:
https://docs.netapp.com/us-en/cloud_volumes/aws/reference_cloud_volume_apis.html
* The complete API documentation is here: https://app.swaggerhub.com/apis/NetApp-Cloud/c-vaa_s
* I recommend using the "API documentation" link from the CVS UI. It will guide you to the API documentation that your environment is using.

## How to use?
1. Obtain access to CVS. See https://cloud.netapp.com/cloud-volumes-service for details.
2. Get the API keys and endpoint from the CVS UI and edit the .conf file and add your keys and the url endpoint for your region

## Requirements
Require bash, curl and jq (for json formatting).
