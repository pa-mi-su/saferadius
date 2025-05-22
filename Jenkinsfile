pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        HELM_RELEASE_NAME = "saferadius"
        HELM_CHART_DIR = "./helm"
        NAMESPACE = "default"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '**']],
                    userRemoteConfigs: [[url: 'https://github.com/pa-mi-su/saferadius.git']]
                ])
            }
        }

        stage('Get Branch Name') {
            steps {
                script {
                    // Extract ref and strip off 'refs/heads/' prefix
                    def rawBranch = sh(script: "git rev-parse --symbolic-full-name HEAD", returnStdout: true).trim()
                    def branchName = rawBranch.replaceFirst(/^refs\/heads\//, '')

                    echo "📌 Extracted branch: ${branchName}"
                    env.BRANCH = branchName
                }
            }
        }

        stage('Build Services') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            echo "🔨 Building ${svc}"
                            sh "mvn clean install -DskipTests=false"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression { env.BRANCH == 'main' || env.BRANCH == 'dev' }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            echo "🐳 Building Docker image for ${svc}"
                            sh "docker build -t ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH} ."
                            echo "📤 Pushing image"
                            sh "docker push ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy to EKS') {
            when {
                expression { env.BRANCH == 'main' || env.BRANCH == 'dev' }
            }
            steps {
                script {
                    echo "🚀 Deploying ${env.BRANCH} to EKS via Helm"
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_DIR} \
                            --namespace ${NAMESPACE} \
                            --set image.tag=${env.BRANCH} \
                            --set image.registry=${REGISTRY} \
                            --set image.repository=${DOCKERHUB_USERNAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline success"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}
