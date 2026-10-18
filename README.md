# Portfolio site

My portfolio, built as a macOS desktop in a single `index.html` with no framework or build step. The Projects folder holds case studies of nine AWS projects, each linked to its repo.

It runs on AWS: a private S3 bucket behind CloudFront, reachable only through CloudFront's origin access control, with HTTPS and CloudFront's managed security headers. It uses CloudFront's own domain, so there is no Route 53 zone or certificate to pay for.

## Layout

- `index.html`, `print.css`, `favicon.svg`, `assets/`: the site
- `terraform/`: bucket, distribution and the deploy role
- `.github/workflows/ci.yml`: checks the page's scripts parse and every file it references exists; Terraform fmt, tflint and validate
- `.github/workflows/deploy.yml`: on a push to `main` that changes the site, uploads it and clears the CloudFront cache

## Deploying

The infrastructure is applied from my machine. GitHub Actions only uploads site files, using an OIDC role limited to this bucket and this distribution and to pushes on `main`. No AWS keys are stored.

```
cd terraform
terraform init -backend-config="bucket=<state bucket>" -backend-config="region=eu-west-2"
terraform apply
```

Then set the repository variables `DEPLOY_ROLE_ARN`, `SITE_BUCKET` and `DISTRIBUTION_ID` from `terraform output`.

## Decisions and what they cost

- Single file, no build: anyone can read the source as it is served. The file is large (about 190 KB) and editing it needs care.
- CloudFront default domain: free and needs no DNS, but the address is not memorable. A custom domain can be added later with an ACM certificate and a Route 53 alias.
- Caching: the page is cached for five minutes and media for a day, and each deploy clears the cache, so changes show within minutes.
- Infrastructure applied by hand: CI cannot change the bucket or distribution, at the cost of one manual step when the Terraform changes.
