# 🛡️ SafeRadius

        **SafeRadius** is a production-ready Java Spring Boot microservices platform with centralized Docker Compose deployment. It features secure authentication, service discovery, and modular REST APIs — designed for fast local or EC2-based deployment and testing.

        ---

        ## 🧰 What is Inside

        - 🔐 `user-service` — JWT auth (register/login)
        - 🌐 `api-gateway` — central entry point, routes traffic securely
        - 🔍 `discovery-server` — Eureka service registry
        - 📥 `location-service` — reverse-geocodes GPS coordinates
        - 🚨 `crime-service` — queries crime stats by coordinates + radius
        - 🐳 `docker-compose.yml` — spins up the full platform

        ---

        ## 🗂️ Project Structure

        ```
        saferadius/
        ├── user-service/
        ├── api-gateway/
        ├── discovery-server/
        ├── location-service/
        ├── crime-service/
        ├── docker-compose.yml
        ```

        ---

        ## 🧪 How to Use

        ### 1️⃣ Build All Microservices

        ```bash
        mvn clean install
        ```

        ### 2️⃣ Build and Push Docker Images

        ```bash
        docker build -t paumicsul/user-service ./user-service
        docker push paumicsul/user-service

        # Repeat for each service...
        ```

        ### 3️⃣ Run Everything with Docker Compose

        ```bash
        docker-compose pull
        docker-compose up -d
        ```

        ---

        ## 🔐 Security

        - JWT-based auth via `user-service`
        - API Gateway secures and routes external traffic
        - Environment variables managed via `.env` file
        - PostgreSQL can be hosted externally or as a container

        ---

        ## 📚 API Documentation

        Swagger UI is enabled on each service:

        ```
        http://<public-ip>:<port>/swagger-ui.html
    ```

    You can test endpoints directly from the browser using Swagger.

    ---

    ## 🔀 Branching & Release Strategy

    SafeRadius follows a GitFlow-inspired branching model:

    | Branch         | Purpose                            |
    |----------------|-------------------------------------|
    | `main`         | Production-ready code, auto-deployed via CI/CD |
    | `dev`          | Integration/testing branch for features |
    | `feature/*`    | New feature branches (e.g., `feature/login-endpoint`) |
    | `bugfix/*`     | Bug fixes (e.g., `bugfix/token-expiry`) |
    | `release/*`    | Release stabilization branches (e.g., `release/1.0.0`) |

    ### CI/CD Pipeline Integration

    - `main` branch → deploys to **EC2**
    - `dev` branch → deploys to **staging EC2**
    - `feature/*` and `bugfix/*` → run build/test only

    ---

    ## 🤖 Future Additions

    - Kafka support
    - Prometheus + Grafana for observability
    - Rate limiting & circuit breakers

    ---

    ## 📄 License

    MIT — open for extension, sharing, and learning 🚀

    ---

    ## 🧭 What is SafeRadius?

    **SafeRadius** helps users assess crime risk in their current location. A user clicks “Locate Me,” and the system:

    1. Captures GPS coordinates
    2. Reverse-geocodes the coordinates into a real address
    3. Searches recent crime data within a 1, 2, or 5-mile radius
    4. Returns a list of nearby crime incidents and their types

    The system is built as a scalable, modular microservices platform using Spring Boot and Docker Compose.

    ---

    ## 🧱 Architecture Overview

    ```
    [ User (Web / iOS) ]
    │
    ▼
    [ API Gateway ]
    │
    ┌──────┼─────────────┬────────────┐
    ▼      ▼             ▼            ▼
    User  Location     Crime     Discovery
    Svc     Svc        Svc         Svc
    ```

    - **user-service**: handles registration, login, and JWT issuance
    - **location-service**: takes lat/lng and returns the real address
    - **crime-service**: searches nearby crime data and returns results
    - **api-gateway**: central entrypoint for all services
    - **discovery-server**: Eureka registry for service discovery
