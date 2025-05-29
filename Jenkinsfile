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
        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "🔨 Building and testing ${svc}"
                            sh 'mvn clean install -DskipTests=false'
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
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                        for (svc in services) {
                            dir(svc) {
                                def image = "${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${IMAGE_TAG}"
                                echo "🐳 Building Docker image for ${svc}"
                                sh 'mvn clean install -DskipTests'
                                sh 'cp target/*.jar app.jar'
                                sh "docker build --platform linux/amd64 -t ${image} ."
                                sh "docker push ${image}"
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2 via Git + Docker Compose') {
            steps {
                script {
                    writeFile file: '.env', text: "IMAGE_TAG=${IMAGE_TAG}"
                    sshagent(['ec2-runtime-ssh']) {
                        sh """
                            echo "🚀 Uploading .env to EC2"
                            scp -o StrictHostKeyChecking=no .env ${EC2_USER}@${EC2_HOST}:${EC2_DIR}/.env

                            echo "🚀 Pulling latest code and restarting containers"
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
            echo "✅ Pipeline completed successfully."
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
    }
}
