provider "aws" {
  region = "us-east-1"
  #Add Default Tags for deployed resources below
  default_tags {
    tags = {
      Environment            = "Joel Cloudtrail Analyzer",
      Point-Of-Contact       = "Joel Gray",
      Point-of-Contact-Email = "joelgrayiii@hotmail.com"
    }
  }
}