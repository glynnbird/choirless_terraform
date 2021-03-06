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
                             "${aws_s3_bucket.choirlessSnapshot.arn}/*",
			     "${aws_s3_bucket.choirlessDefinition.arn}",
                             "${aws_s3_bucket.choirlessDefinition.arn}/*",
			     "${aws_s3_bucket.choirlessFinalParts.arn}",
                             "${aws_s3_bucket.choirlessFinalParts.arn}/*",
			     "${aws_s3_bucket.choirlessFinal.arn}",
                             "${aws_s3_bucket.choirlessFinal.arn}/*",
			     "${aws_s3_bucket.choirlessPreview.arn}",
                             "${aws_s3_bucket.choirlessPreview.arn}/*",
			     "${aws_s3_bucket.choirlessMisc.arn}",
                             "${aws_s3_bucket.choirlessMisc.arn}/*",
			     "${aws_s3_bucket.choirlessConverted.arn}",
                             "${aws_s3_bucket.choirlessConverted.arn}/*"
			    ]
            },
            {
                "Effect": "Allow",
                "Action": [ "dynamodb:*" ],
                "Resource": ["arn:aws:dynamodb:*:*:table/*"]
            }

        ]
  }
  EOF
}

#this policy grants access to mount and write to the EFS file system

resource "aws_efs_file_system_policy" "choirlessEFSPolicy" {
  file_system_id = aws_efs_file_system.choirlessEFS.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "choirlessEFSPolicy",
    "Statement": [
        {
            "Sid": "Statement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.choirlessEFS.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
}
