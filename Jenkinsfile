pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/paumicsul"
        PROD_NAMESPACE = "saferadius-prod"
        STAGING_NAMESPACE = "saferadius-staging"
        MAVEN_OPTS = "-Dmaven.repo.local=.m2/repository"
    }

    options {
        skipDefaultCheckout true
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                // ⏬ Clone the source code from GitHub
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    echo "🔍 BRANCH_NAME = ${env.BRANCH_NAME}, GIT_BRANCH = ${env.GIT_BRANCH}"

                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            echo "🔨 Building and testing ${svc}"
                            sh "mvn clean install -DskipTests=false"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression {
                    def branch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'unknown'
                    echo "🧭 Docker stage on branch: ${branch}"
                    return branch == 'main' || branch == 'dev'
                }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']

                    // 🔐 Docker Hub login using Jenkins credentials
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }

                    services.each { svc ->
                        dir(svc) {
                            echo "📦 Building and pushing Docker image for ${svc}"
                            sh "docker build -t $REGISTRY/${svc}:${env.BRANCH_NAME} ."
                            sh "docker push $REGISTRY/${svc}:${env.BRANCH_NAME}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy') {
            when {
                expression {
                    def branch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'unknown'
                    echo "🧭 Helm stage on branch: ${branch}"
                    return branch == 'main' || branch == 'dev'
                }
            }
            steps {
                script {
                    def namespace = (env.BRANCH_NAME == 'main') ? PROD_NAMESPACE : STAGING_NAMESPACE

                    // 🔧 Configure kubectl with AWS EKS cluster
                    sh '''
                        aws eks --region us-east-1 update-kubeconfig --name saferadius
                    '''

                    // 🚀 Deploy Helm chart to EKS
                    echo "🚀 Deploying to namespace: ${namespace}"
                    sh "helm upgrade --install saferadius ./helm -n ${namespace} --create-namespace --debug"
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
