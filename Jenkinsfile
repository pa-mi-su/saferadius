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

    stages {
        stage('📦 Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "\u001B[34m🔨 Building and testing ${svc}...\u001B[0m"
                            sh 'mvn clean install -DskipTests=false'
                            echo "\u001B[32m✅ Build successful for ${svc}\u001B[0m"
                        }
                    }
                }
            }
        }

        stage('🐳 Docker Build & Push') {
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
                                echo "\u001B[36m📁 Directory: ${svc}\u001B[0m"
                                sh 'mvn clean install -DskipTests'
                                sh 'cp target/*.jar app.jar'
                                echo "\u001B[33m🐳 Building Docker image for ${svc}\u001B[0m"
                                sh "docker build --platform linux/amd64 -t ${image} ."
                                echo "\u001B[36m📤 Pushing Docker image: ${image}\u001B[0m"
                                sh "docker push ${image}"
                            }
                        }
                    }
                }
            }
        }

        stage('🚀 Deploy to EC2 via Git + Docker Compose') {
            steps {
                script {
                    writeFile file: '.env', text: "IMAGE_TAG=${IMAGE_TAG}"
                    sshagent(['ec2-runtime-ssh']) {
                        echo "\u001B[35m📡 Connecting to EC2 and deploying...\u001B[0m"
                        sh """
                            echo "\u001B[33m📤 Uploading .env to EC2\u001B[0m"
                            scp -o StrictHostKeyChecking=no .env ${EC2_USER}@${EC2_HOST}:${EC2_DIR}/.env

                            echo "\u001B[34m🔄 Pulling latest code and restarting containers\u001B[0m"
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} << 'EOF'
                                cd ${EC2_DIR}
                                git pull origin main
                                docker-compose down
                                docker-compose pull
                                docker-compose up -d --remove-orphans
EOF
                        """
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
            echo "\u001B[31m❌ Pipeline failed. Check the logs above for details.\u001B[0m"
        }
    }
}
