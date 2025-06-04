pipeline {
    agent any

    parameters {
        choice(name: 'STAGE_TO_RUN', choices: ['all', 'build', 'docker', 'deploy'], description: 'Choose which pipeline stage to run')
    }

    options {
        ansiColor('xterm') // 🔥 Enables ANSI color output
    }

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
            when {
                anyOf {
                    expression { params.STAGE_TO_RUN == 'all' }
                    expression { params.STAGE_TO_RUN == 'build' }
                }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "\u001B[1;34m🔨 Building and testing ${svc}...\u001B[0m"
                            sh 'mvn clean install -DskipTests=false'
                            echo "\u001B[1;32m✅ Build successful for ${svc}\u001B[0m"
                        }
                    }
                }
            }
        }

        stage('🐳 Docker Build & Push') {
            when {
                allOf {
                    anyOf {
                        expression { params.STAGE_TO_RUN == 'all' }
                        expression { params.STAGE_TO_RUN == 'docker' }
                    }
                    anyOf {
                        branch 'main'
                        branch 'dev'
                    }
                }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        echo "\u001B[1;36m🔐 Logging into Docker Hub...\u001B[0m"
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                        for (svc in services) {
                            dir(svc) {
                                def image = "${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${IMAGE_TAG}"
                                echo "\u001B[1;35m📁 Building Docker image: ${svc}\u001B[0m"
                                sh 'mvn clean install -DskipTests'
                                sh 'cp target/*.jar app.jar'
                                sh "docker build --platform linux/amd64 -t ${image} ."
                                sh "docker push ${image}"
                                echo "\u001B[1;32m✅ Docker image pushed: ${image}\u001B[0m"
                            }
                        }
                    }
                }
            }
        }

        stage('🚀 Deploy to EC2 via Git + Docker Compose') {
            when {
                anyOf {
                    expression { params.STAGE_TO_RUN == 'all' }
                    expression { params.STAGE_TO_RUN == 'deploy' }
                }
            }
            steps {
                script {
                    writeFile file: '.env', text: "IMAGE_TAG=${IMAGE_TAG}"
                    sshagent(['ec2-runtime-ssh']) {
                        echo "\u001B[1;33m📡 Deploying to EC2...\u001B[0m"
                        sh """
                            echo "\u001B[1;33m📤 Uploading .env to EC2\u001B[0m"
                            scp -o StrictHostKeyChecking=no .env ${EC2_USER}@${EC2_HOST}:${EC2_DIR}/.env

                            echo "\u001B[1;34m🔄 Pulling latest code on EC2...\u001B[0m"
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "
                                cd ${EC2_DIR} &&
                                git pull origin ${BRANCH_NAME} &&
                                docker compose pull &&
                                docker compose down &&
                                docker compose up -d
                            "
                        """
                        echo "\u001B[1;32m✅ Deployment complete.\u001B[0m"
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully.'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}
