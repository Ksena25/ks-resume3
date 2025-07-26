name: Build, Push, and Deploy Image

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  id-token: write 
  contents: read
  pull-requests: write 

env:
  AWS_REGION: ${{secrets.AWS_REGION}}
  AWS_ROLE: ${{secrets.AWS_ACTIONS_ROLE}}
  ECR_REPO_NAME: ${{secrets.ECR_REPO_NAME}}
  IMAGE_TAG: ${{github.run_number}}


jobs:
  Build:
    runs-on: ubuntu-latest ## the github runner or shared runner
    steps:
      - name: Clone repo
        uses: actions/checkout@v3
      - name: AWS Creds Config # aws account credentials configuration
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{env.AWS_ROLE}} # OIDC Open ID Connect
          aws-region: ${{env.AWS_REGION}}
      
      - name: Login to ECR 
        uses: aws-actions/amazon-ecr-login@v1
        with: 
          mask-password: true
        id: ecr-login
      - name: Build tag and push image
        id: build-and-push
        run: |
            docker build -t ${{steps.ecr-login.outputs.registry}}/${{env.ECR_REPO_NAME}}:${{env.IMAGE_TAG}} .
            
      - name: Scan docker Image for vulnerabilities 
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "${{steps.ecr-login.outputs.registry}}/${{env.ECR_REPO_NAME}}:${{env.IMAGE_TAG}}" # Scans the built image
          format: "table"
          exit-code: "0"
          severity: "CRITICAL,HIGH"
      - name: push image to ECR
        run: |
          docker push ${{steps.ecr-login.outputs.registry}}/${{env.ECR_REPO_NAME}}:${{env.IMAGE_TAG}}

      - name: store image in github env
        run: echo "Image=${{steps.ecr-login.outputs.registry}}/${{env.ECR_REPO_NAME}}:${{env.IMAGE_TAG}}" >> $GITHUB_ENV
  Deploy:
    runs-on: ubuntu-latest
    needs: build
      





       

