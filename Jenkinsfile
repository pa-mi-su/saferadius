pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:/usr/bin:/bin"
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        IMAGE_TAG = "${env.BRANCH_NAME}"
        EC2_USER = "ubuntu"
        EC2_HOST = "44.204.5.96"
        EC2_DIR = "/home/ubuntu/safe-radius"
    }

    options {
        ansiColor('xterm') // Enables ANSI color output
    }

    stages {
        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "\u001B[36m🔨 Starting build for: ${svc}\u001B[0m"
                            echo "\u001B[35m📁 Directory: $(pwd)\u001B[0m"
                            echo "\u001B[33m📦 Running Maven clean install...\u001B[0m"
                            sh 'mvn clean install -DskipTests=false || { echo "\u001B[31m❌ Build failed\u001B[0m"; exit 1; }'
                            echo "\u001B[32m✅ Build succeeded for ${svc}\u001B[0m"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                anyOf {
                    branch 'main'
                    branch 'dev'
                }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        echo "\u001B[36m🔐 Logging into Docker Hub...\u001B[0m"
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'

                        for (svc in services) {
                            dir(svc) {
                                def image = "${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${IMAGE_TAG}"
                                echo "\u001B[36m🐳 Building Docker image for ${svc}\u001B[0m"
                                echo "\u001B[33m📋 Verifying JAR file presence...\u001B[0m"
                                sh 'ls -lh target || echo "\u001B[31m❌ No target directory!\u001B[0m"'

                                sh 'mvn clean install -DskipTests || { echo "\u001B[31m❌ Maven build failed\u001B[0m"; exit 1; }'
                                sh 'cp target/*.jar app.jar || { echo "\u001B[31m❌ Failed to copy JAR\u001B[0m"; exit 1; }'
                                echo "\u001B[36m🏗️ Docker build for ${svc}...\u001B[0m"
                                sh "docker build --platform linux/amd64 -t ${image} . || { echo '\u001B[31m❌ Docker build failed\u001B[0m'; exit 1; }"
                                echo "\u001B[35m📤 Pushing ${image} to Docker Hub...\u001B[0m"
                                sh "docker push ${image} || { echo '\u001B[31m❌ Docker push failed\u001B[0m'; exit 1; }"
                                echo "\u001B[32m✅ Docker image pushed: ${image}\u001B[0m"
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2 via Git + Docker Compose') {
            steps {
                script {
                    echo "\u001B[33m📝 Writing .env file...\u001B[0m"
                    writeFile file: '.env', text: "IMAGE_TAG=${IMAGE_TAG}"

                    sshagent(['ec2-runtime-ssh']) {
                        echo "\u001B[36m🔑 Connecting to EC2...\u001B[0m"
                        sh """
                            echo "\u001B[35m📤 Uploading .env to EC2\u001B[0m"
                            scp -o StrictHostKeyChecking=no .env ${EC2_USER}@${EC2_HOST}:${EC2_DIR}/.env || { echo '\u001B[31m❌ SCP failed\u001B[0m'; exit 1; }

                            echo "\u001B[36m🔄 Deploying with docker-compose...\u001B[0m"
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} << 'EOF'
                                set -e
                                cd ${EC2_DIR}
                                echo "\u001B[33m📥 Pulling latest code...\u001B[0m"
                                git pull origin main

                                echo "\u001B[35m🧹 Stopping old containers\u001B[0m"
                                docker-compose down || echo "\u001B[33m⚠️ Nothing to stop\u001B[0m"

                                echo "\u001B[36m📦 Pulling images...\u001B[0m"
                                docker-compose pull || { echo '\u001B[31m❌ Pull failed\u001B[0m'; exit 1; }

                                echo "\u001B[32m🚀 Starting services...\u001B[0m"
                                docker-compose up -d --remove-orphans || { echo '\u001B[31m❌ Compose up failed\u001B[0m'; exit 1; }
EOF
                        """
                        echo "\u001B[32m✅ EC2 deployment completed!\u001B[0m"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "\u001B[32m✅ Pipeline completed successfully.\u001B[0m"
        }
        failure {
            echo "\u001B[31m❌ Pipeline failed. See logs above.\u001B[0m"
        }
    }
}
