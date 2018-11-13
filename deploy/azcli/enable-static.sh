#!/bin/bash

az storage blob service-properties update --account-name $STORAGE_NAME --static-website  --index-document index.html --404-document 404.html 
