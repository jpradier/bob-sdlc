# Multi-stage build for Java 21 Spring Boot application

# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom.xml and download dependencies (cached layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM gcr.io/distroless/java21-debian12:nonroot

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run as non-root user (distroless already uses nonroot user)
USER nonroot:nonroot

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD ["/usr/bin/java", "-cp", "app.jar", "org.springframework.boot.loader.JarLauncher", "--management.endpoint.health.enabled=true"]

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]