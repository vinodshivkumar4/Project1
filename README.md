# DevOps End-to-End Pipeline Project

This project demonstrates a fully automated DevSecOps pipeline that provisions AWS infrastructure, performs security scanning, builds a containerized Node.js application, and deploys it to an EC2 instance.

## 🚀 Architecture Overview
The system follows a modern CI/CD workflow:
1.  **Infrastructure:** Provisioned via **Terraform** (AWS EC2, Security Groups, SSH Keys).
2.  **CI/CD Engine:** **Jenkins** handles the automation.
3.  **Security:** **Trivy** performs a filesystem scan for secrets and misconfigurations.
4.  **Containerization:** The application is packaged using **Docker**.
5.  **Registry:** Images are stored in **Docker Hub**.
6.  **Deployment:** Automated via **SSH and Shell Scripting** to the target EC2.

## 🛠️ Prerequisites
- **Jenkins Server** with Docker and Terraform installed.
- **AWS Credentials** configured in Jenkins (via Environment variables or IAM Role).
- **Docker Hub Account** with credentials stored in Jenkins as `docker-hub-creds`.
- **Terraform Backend:** An S3 bucket for storing the state file.

## 📂 Project Structure
- `/app`: The Node.js source code and Dockerfile.
- `/Terraform`: Infrastructure as Code files.
- `/scripts`: Automation scripts for deployment.
- `Jenkinsfile`: The pipeline definition.

## 🏃 Running the Pipeline End-to-End
1.  **Code Push:** Push a change to the `master` branch of the GitHub repository.
2.  **Trigger:** Jenkins detects the push and starts the build.
3.  **Provision:** Terraform checks the state and ensures the EC2 instance is running.
4.  **Scan:** Trivy audits the code for security risks.
5.  **Push:** Docker builds the new image and pushes it to your registry.
6.  **Deploy:** The deployment script pulls the fresh image onto the EC2 instance and restarts the container.
7.  **Verify:** The pipeline performs a `curl` health check to confirm the app is live.
