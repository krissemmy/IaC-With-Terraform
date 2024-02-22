# IaC-With-Terraform

## Overview

This Project demonstrates the use of Terraform as Infrastructure as Code to provision resources in AWS, leveraging services such as:
-  AWS SNS
-  AWS Lambda (Lambda Function)
-  AWS Glue (Glue Job)
-  AWS S3
-  Amazon DynamoDB
-  Amazon Kinesis (Kinesis Stream and Amazon Data Firehose)



### Code Overview
The pipeline comprises the following components:

- **S3 Bucket (data-bucket):** Stores raw data for processing.

- **Lambda Function (etl-lambda):** Processes data uploaded to the S3 bucket and writes it to DynamoDB.

- **DynamoDB Table (target-table):** Stores the processed data.

- **Glue Job (my-glue):** Orchestrates the data processing logic defined in a Python script.

- **SNS Topic (user-updates):** Publishes notifications about data processing events.

- **Kinesis Stream (test-stream):** Streams data for real-time processing.

- **Kinesis Firehose Delivery Stream (extended_s3_stream):** Delivers data from the Kinesis stream to an S3 bucket with additional processing using a Lambda function.

- **S3 Bucket (bucket):** Stores the processed data delivered by the Kinesis Firehose.

- **Lambda Function (firehose_lambda_processor):** Processes data delivered by the Kinesis Firehose before storing it in the S3 bucket.


## Deployment and Usage
### Prerequisites:
- Configure AWS credentials and region in your Terraform environment.
- Install Terraform and the AWS provider plugin.
### Deployment:
- Update the `source_bucket_name` and `destination_bucket_name` variables in the variables.tf file with your desired bucket names.
- **Initialize Terraform:** `terraform init`
- **Apply the Terraform configuration:** `terraform apply`

## Testing
- Upload data to the data-bucket.
- The etl-lambda function will be triggered and process the data, storing the results in the target-table.
- Optionally, you can publish messages to the user-updates topic to trigger notifications.
- Optionally, send data to the test-stream for real-time processing and storage in the bucket.


## Images
Below are images that show the different resources in AWS.

![alt text](images/image.png)
*Terminal Result of Successful Resources Creation*

![alt text](images/image-1.png)
*Kinesis Data Stream*

![alt text](images/image-2.png)
*Kinesis Data Stream(detailed)*

![alt text](images/image-3.png)
*Amazon Data Firehose*

![alt text](images/image-4.png)
*Amazon Data FireHose(detailed)*

![alt text](images/image-5.png)
*DynamoDB Table*

![alt text](images/image-6.png)
*DynamoDB Table(detailed)*

![alt text](images/image-7.png)
*Lambda Functions*

![alt text](images/image-8.png)
*Lambda Function code*

![alt text](images/image-9.png)
*Glue Job*

![alt text](images/image-10.png)
*SNS Topic*

![alt text](images/image-11.png)
*The Two S3 Buckets*

![alt text](images/image-12.png)
*Terminal Result of Resources Destroyed Successfully*


### Additional Information

In addition to the resources mentioned above, it's important to note the following:

- Security Considerations: Ensure that appropriate IAM roles and policies are in place to restrict access to these resources based on the principle of least privilege.

- Monitoring and Logging: Implement monitoring solutions such as CloudWatch alarms and CloudTrail logging to track resource usage, detect anomalies, and troubleshoot issues.

- Cost Optimization: Regularly review the usage of these resources to optimize costs, considering options like Reserved Instances, Spot Instances, or utilizing AWS Cost Explorer for cost analysis.

- Scaling: Evaluate the scalability of the infrastructure to handle increased workloads and consider implementing auto-scaling where applicable.

- Backup and Disaster Recovery: Establish backup mechanisms for critical data stored in DynamoDB and S3 buckets, and devise a disaster recovery plan to ensure business continuity in case of failures.

By following best practices in managing and maintaining these resources, you can ensure a robust and efficient infrastructure that meets your application's requirements while leveraging the power of Terraform and AWS services.
