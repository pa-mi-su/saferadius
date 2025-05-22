pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        IMAGE_TAG = "latest"
        HELM_RELEASE_NAME = "saferadius"
        HELM_CHART_DIR = "./helm"
        NAMESPACE = "default"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Get Branch Name') {
            steps {
                script {
                    def branch = sh(
                        script: "git rev-parse --abbrev-ref HEAD || echo unknown",
                        returnStdout: true
                    ).trim()
                    if (branch == "HEAD") {
                        branch = sh(
                            script: "git name-rev --name-only HEAD || echo unknown",
                            returnStdout: true
                        ).trim()
                    }
                    echo "📌 Using branch: ${branch}"
                    env.BRANCH = branch
                }
            }
        }

        stage('Build All Services') {
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
                expression { env.BRANCH == "main" || env.BRANCH == "dev" }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            echo "🐳 Docker build for ${svc}"
                            sh "docker build -t ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH} ."
                            sh "docker push ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy to EKS') {
            when {
                expression { env.BRANCH == "main" || env.BRANCH == "dev" }
            }
            steps {
                script {
                    echo "🚀 Deploying ${env.BRANCH} to EKS"
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
            echo "✅ Success"
        }
        failure {
            echo "❌ Failed"
        }
    }
}
