resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"

  lifecycle {
    prevent_destroy = true
  }
}

# Future CloudFront integration.
# resource "aws_iam_service_linked_role" "cloudfront_vpc_origin" {
#   aws_service_name = "vpcorigin.cloudfront.amazonaws.com"
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# Future Application Load Balancer integration.
# resource "aws_iam_service_linked_role" "elb" {
#   aws_service_name = "elasticloadbalancing.amazonaws.com"
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }