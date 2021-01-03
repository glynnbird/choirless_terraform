data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "choirless-terraform-state"
    key = "choirless"
    region = "eu-west-1"
  }
}


resource "aws_iam_role" "choirlessLambdaRole" {
  name = "choirlessLambdaRole-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = var.tags
}

//add inline policy that allows writing to logs and invoking lambda functions

resource "aws_iam_role_policy" "choirlessInlinePolicy" {
  name = "choirlessInlinePolicy"
  role = aws_iam_role.choirlessLambdaRole.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": "arn:aws:logs:*:*:*"
            },
            { 
                "Effect": "Allow", 
                "Action": [ "lambda:InvokeFunction" ], 
                "Resource": ["*"]
	    },
            { 
                "Effect": "Allow",
                "Action": [ "s3:Get*",
            		    "s3:List*",
                            "s3:*Object"],
                "Resource": ["${aws_s3_bucket.choirlessRaw.arn}",
                             "${aws_s3_bucket.choirlessRaw.arn}/*",
			     "${aws_s3_bucket.choirlessSnapshot.arn}",
                             "${aws_s3_bucket.choirlessSnapshot.arn}/*"
			    ]
            }

        ]
  }
  EOF
}


# create an API gateway
resource "aws_api_gateway_rest_api" "choirless_api" {
  name = "choirless-${terraform.workspace}"

  tags = var.tags
}

module "api_method" {
  for_each = toset(var.api_methods)
  source = "./modules/apimethod"
  api_id = aws_api_gateway_rest_api.choirless_api.id
  api_root_resource_id = aws_api_gateway_rest_api.choirless_api.root_resource_id
  api_path_part = each.key
  api_method = "POST" 
  api_lambda_arn = aws_lambda_function.lambda[each.key].arn
  api_lambda_name = aws_lambda_function.lambda[each.key].function_name
  api_region = data.aws_region.current.name
  api_account_id = data.aws_caller_identity.current.account_id
}

# create api gateway deployment
resource "aws_api_gateway_deployment" "choirless_api_deployment" {
  depends_on = [module.api_method]
  rest_api_id = aws_api_gateway_rest_api.choirless_api.id
  stage_name = terraform.workspace
}

