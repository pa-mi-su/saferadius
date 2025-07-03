pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "localhost"       // or your DockerHub/ECR/GCR registry
        BUILD_TAG = "${env.BUILD_NUMBER}"
        HELM_NAMESPACE = "saferadius"
    }

    stages {
        stage('Init') {
            steps {
                script {
                    SERVICES = [
                        [name: 'user-service', port: 8081],
                        [name: 'crime-service', port: 8082],
                        [name: 'api-gateway', port: 8083],
                        [name: 'location-service', port: 8084],
                        [name: 'discovery-server', port: 8761]
                    ]
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    for (svc in SERVICES) {
                        def imageTag = "${DOCKER_REGISTRY}/${svc.name}:${BUILD_TAG}"
                        dir("${svc.name}") {
                            sh """
                                echo "🔨 Building image for ${svc.name}"
                                docker build -t ${imageTag} .
                                docker tag ${imageTag} ${DOCKER_REGISTRY}/${svc.name}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                script {
                    sh "kubectl create namespace ${HELM_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"

                    for (svc in SERVICES) {
                        def chartPath = "${svc.name}/chart"
                        def imageTag = "${DOCKER_REGISTRY}/${svc.name}:${BUILD_TAG}"
                        sh """
                            echo "🚀 Deploying ${svc.name} using Helm"
                            helm upgrade --install ${svc.name} ${chartPath} \
                                --namespace ${HELM_NAMESPACE} \
                                --set image.repository=${DOCKER_REGISTRY}/${svc.name} \
                                --set image.tag=${BUILD_TAG} \
                                --set service.port=${svc.port}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ All services built and deployed to Minikube"
        }
        failure {
            echo "❌ Build or deployment failed. Check logs."
        }
    }
}
