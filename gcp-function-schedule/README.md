# GCP Cloud Function HTTPS Trigger

Opinionated module to create a GCP 2nd gen Cloud Function, without  the need to create a separate zip file and
upload it to GCS, and without the need to create a separate service account and manually assign roles to it.

The module will create  the zip-file, upload it to GCS, create a service account for the function, assign the `roles` you specified to it,
and allow invocation by the members specified in `invokers` (if any). 


## Example

```HCL
module "cloud-function-scheduled" {
  source         = "github.com/getml/terraform-modules/gcp-function-https"
  entry_point    = "main"
  function_name  = "cobi-slack-entrypoint"
  function_path  = "../src"
  project_id     = "c17-bot"
  region         = "europe-west1"
  runtime        = "python311"
  available_memory = "256Mi"
  roles          = ["roles/datastore.user", "roles/pubsub.viewer", "roles/pubsub.publisher", "roles/secretmanager.secretAccessor"]
  new_pubsub_topic = "cobi-incoming-messages"
}
```

## Inputs

| Name                           | Description                                                                                                                                                                     | Type         | Default   | Required |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | --------- | -------- |
| entry_point                    | The name of the function (as defined in source code) that will be executed.                                                                                                     | string       |           | YES      |
| function_name                  | The function_name must be a string of alphanumeric, hyphen, and underscore characters, and upto 255 characters in length.                                                       | string       |           | YES      |
| function_path                  | The (relative) path where the source code for the function can be found. Must point to a directory.                                                                             | string       |           | YES      |
| project_id                     | The GCP project identifier where the function will be created.                                                                                                                  | string       |           | YES      |
| region                         | The location (region) in which the function will be deployed.                                                                                                                   | string       |           | YES      |
| runtime                        | The runtime in which to run the function.                                                                                                                                       | string       |           | YES      |
| all_traffic_on_latest_revision | Whether 100% of traffic is routed to the latest revision. Defaults to true.                                                                                                     | bool         | TRUE      | NO       |
| available_memory               | The amount of memory available for a function. Defaults to 128M. Supported units are k, M, G, Mi, Gi. If no unit is supplied the value is interpreted as bytes.                 | string       | 128Mi     | NO       |
| environment_variables          | User-provided build-time environment variables for the function.                                                                                                                | map(string)  | {}        | NO       |
| ingress_settings               | Available ingress settings. Defaults to ALLOW_ALL if unspecified. Default value is ALLOW_ALL. Possible values are ALLOW_ALL, ALLOW_INTERNAL_ONLY, and ALLOW_INTERNAL_AND_GCLB.  | string       | ALLOW_ALL | NO       |
| invokers                       | The list of members that can invoke the function. Include allUsers to make the function public.                                                                                 | list(string) | []        | NO       |
| max_instance_count             | The limit on the maximum number of function instances that may coexist at a given time.                                                                                         | number       | 1         | NO       |
| min_instance_count             | The limit on the minimum number of function instances that may coexist at a given time.                                                                                         | number       | 0         | NO       |
| new_pubsub_topic               | The name of the Pub/Sub topic to which messages will be published. Default is to create no topic.                                                                               | string       | null      | NO       |
| roles                          | The list of roles to assign to the service account that the Cloud Function will use.                                                                                            | list(string) | []        | NO       |
| schedule                       |                                                                                                                                                                                 | string       | null      | NO       |
| schedule_attempt_deadline      |                                                                                                                                                                                 | string       | 320s      | NO       |
| schedule_description           |                                                                                                                                                                                 | string       | ""        | NO       |
| schedule_retry_count           |                                                                                                                                                                                 | number       | 0         | NO       |
| schedule_timezone              |                                                                                                                                                                                 | string       | UTC       | NO       |
| timeout_seconds                | The function execution timeout. Execution is considered failed and can be terminated if the function is not completed at the end of the timeout period. Defaults to 60 seconds. | number       | 60        | NO       |
| vpc_connector                  | The Serverless VPC Access connector that this cloud function can connect to.                                                                                                    | string       | null      | NO       |
| vpc_connector_egress_settings  | This should be a fully qualified URI in this format: projects/\*/locations/\*/connectors/\*.                                                                                    | string       | null      | NO       |