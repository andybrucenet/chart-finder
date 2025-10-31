# IAM Roles

- Store one JSON trust policy per IAM role in this directory; each file describes which AWS service or principal is allowed to assume the role.
- Name files after their purpose (e.g., `codebuild-exec-trust.json`) so it is obvious which automation, pipeline, or actor should use the trust relationship.
- Keep usage notes—including the AWS CLI commands for creating or updating the role—in the sibling documentation files so that policy documents remain valid JSON without comments.
